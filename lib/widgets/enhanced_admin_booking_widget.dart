import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/booking_model.dart';
import '../providers/booking_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/logger.dart';

class EnhancedAdminBookingWidget extends StatefulWidget {
  const EnhancedAdminBookingWidget({Key? key}) : super(key: key);

  @override
  State<EnhancedAdminBookingWidget> createState() => _EnhancedAdminBookingWidgetState();
}

class _EnhancedAdminBookingWidgetState extends State<EnhancedAdminBookingWidget> {
  bool _isLoading = false;
  String? _error;
  String _selectedStatusFilter = 'all';
  List<Map<String, dynamic>> _availableWorkers = [];

  @override
  void initState() {
    super.initState();
    // Don't load data here since the parent screen already loads it
    // Just load workers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAvailableWorkers();
    });
  }

  Future<void> _loadAdminData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      
      debugPrint('🔄 Refreshing admin bookings...');
      await bookingProvider.fetchAllBookings();
      
      debugPrint('✅ Admin bookings refreshed: ${bookingProvider.adminBookings.length}');
      
      // Load available workers
      await _loadAvailableWorkers();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Refreshed ${bookingProvider.adminBookings.length} bookings'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
    } catch (e) {
      debugPrint('❌ Error loading admin data: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load bookings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadAvailableWorkers({String serviceType = 'all'}) async {
    try {
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      final workers = await bookingProvider.getAvailableWorkers(serviceType: serviceType);
      setState(() {
        _availableWorkers = workers;
      });
      Logger.info('✅ Loaded ${workers.length} available workers for ${serviceType}');
    } catch (e) {
      Logger.error('❌ Error loading workers', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingProvider>(
      builder: (context, bookingProvider, child) {
        // Debug information
        debugPrint('🔍 Admin Widget Build - Loading: $_isLoading, Error: $_error');
        debugPrint('📊 Admin Bookings Count: ${bookingProvider.adminBookings.length}');
        
        if (_isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading admin bookings...'),
              ],
            ),
          );
        }

        if (_error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Error loading admin data',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadAdminData,
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        }

        final allBookings = bookingProvider.adminBookings;
        final filteredBookings = _getFilteredBookings(allBookings);
        
        debugPrint('📋 All Bookings: ${allBookings.length}, Filtered: ${filteredBookings.length}');

        return Column(
          children: [
            // Admin Dashboard Header
            _buildAdminDashboard(allBookings),
            
            // Filter Section
            _buildFilterSection(),
            
            // Debug Info
            if (allBookings.isNotEmpty)
              Container(
                padding: EdgeInsets.all(8),
                color: Colors.green.shade100,
                child: Text(
                  'Debug: ${allBookings.length} bookings loaded, ${filteredBookings.length} after filter',
                  style: TextStyle(fontSize: 12, color: Colors.green.shade800),
                ),
              ),
            
            // Bookings List
            Expanded(
              child: allBookings.isEmpty
                  ? _buildEmptyState()
                  : filteredBookings.isEmpty
                      ? _buildNoFilterResults()
                      : RefreshIndicator(
                          onRefresh: _loadAdminData,
                          child: ListView.builder(
                            padding: EdgeInsets.all(16),
                            itemCount: filteredBookings.length,
                        itemBuilder: (context, index) {
                          final booking = filteredBookings[index];
                          return _buildAdminBookingCard(booking);
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAdminDashboard(List<BookingModel> bookings) {
    final statusCounts = <String, int>{};
    for (final booking in bookings) {
      statusCounts[booking.status] = (statusCounts[booking.status] ?? 0) + 1;
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Admin Dashboard',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildDashboardCard('Total', bookings.length.toString(), Colors.blue, Icons.book_online)),
              SizedBox(width: 8),
              Expanded(child: _buildDashboardCard('Pending', (statusCounts['pending'] ?? 0).toString(), Colors.orange, Icons.pending)),
              SizedBox(width: 8),
              Expanded(child: _buildDashboardCard('Active', ((statusCounts['accepted'] ?? 0) + (statusCounts['assigned'] ?? 0) + (statusCounts['in_progress'] ?? 0)).toString(), Colors.purple, Icons.work)),
              SizedBox(width: 8),
              Expanded(child: _buildDashboardCard('Completed', (statusCounts['completed'] ?? 0).toString(), Colors.green, Icons.check_circle)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(String title, String count, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 4),
          Text(
            count,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  List<BookingModel> _getFilteredBookings(List<BookingModel> bookings) {
    if (_selectedStatusFilter == 'all') {
      return bookings;
    }
    return bookings.where((booking) => booking.status == _selectedStatusFilter).toList();
  }

  Widget _buildFilterSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Text(
            'Filter by Status:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          SizedBox(width: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'All'),
                  SizedBox(width: 8),
                  _buildFilterChip('pending', 'Pending'),
                  SizedBox(width: 8),
                  _buildFilterChip('accepted', 'Accepted'),
                  SizedBox(width: 8),
                  _buildFilterChip('assigned', 'Assigned'),
                  SizedBox(width: 8),
                  _buildFilterChip('in_progress', 'In Progress'),
                  SizedBox(width: 8),
                  _buildFilterChip('completed', 'Completed'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedStatusFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatusFilter = value;
        });
      },
      selectedColor: Colors.deepPurple.withOpacity(0.2),
      checkmarkColor: Colors.deepPurple,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No bookings found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Bookings will appear here once customers make requests',
            style: TextStyle(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadAdminData,
            icon: Icon(Icons.refresh),
            label: Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoFilterResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.filter_list_off,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No bookings match filter',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try selecting a different status filter',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedStatusFilter = 'all';
              });
            },
            child: Text('Clear Filter'),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminBookingCard(BookingModel booking) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.serviceDisplayName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      Text(
                        'Customer: ${booking.customerName}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        'ID: ${booking.id.substring(booking.id.length - 8)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    booking.statusDisplayName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Booking Details
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Phone', booking.customerPhone),
                      _buildDetailRow('Address', booking.customerAddress),
                      _buildDetailRow('Date', '${booking.preferredDate.day}/${booking.preferredDate.month}/${booking.preferredDate.year}'),
                      _buildDetailRow('Time', booking.preferredTime),
                      if (booking.paymentAmount != null)
                        _buildDetailRow('Amount', '₹${booking.paymentAmount}'),
                    ],
                  ),
                ),
              ],
            ),

            // Worker Assignment Info
            if (booking.assignedEmployeeName != null) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.engineering, color: Colors.purple, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Assigned to: ${booking.assignedEmployeeName}',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.purple[800],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Admin Actions
            SizedBox(height: 16),
            _buildAdminActions(booking),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminActions(BookingModel booking) {
    List<Widget> actions = [];

    // Accept/Reject for pending bookings
    if (booking.canBeAccepted) {
      actions.addAll([
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _acceptBooking(booking),
            icon: Icon(Icons.check, size: 16),
            label: Text('Accept'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _rejectBooking(booking),
            icon: Icon(Icons.close, size: 16),
            label: Text('Reject'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
      ]);
    }

    // Assign worker for accepted bookings
    if (booking.canAssignWorker) {
      actions.add(
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _assignWorker(booking),
            icon: Icon(Icons.person_add, size: 16),
            label: Text('Assign Worker'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
      );
    }

    // Start work for assigned bookings
    if (booking.canStartWork) {
      actions.add(
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _startWork(booking),
            icon: Icon(Icons.play_arrow, size: 16),
            label: Text('Start Work'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
      );
    }

    // Complete work for in-progress bookings
    if (booking.canCompleteWork) {
      actions.add(
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _completeWork(booking),
            icon: Icon(Icons.done, size: 16),
            label: Text('Complete Work'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
      );
    }

    if (actions.isEmpty) {
      return SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: actions,
    );
  }

  Future<void> _acceptBooking(BookingModel booking) async {
    try {
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      final result = await bookingProvider.acceptBooking(
        booking.id,
        adminNotes: 'Booking accepted by admin',
      );

      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Booking accepted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(result['message']);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept booking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectBooking(BookingModel booking) async {
    final reason = await _showRejectDialog();
    if (reason == null) return;

    try {
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      final result = await bookingProvider.rejectBooking(booking.id, reason);

      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Booking rejected successfully'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        throw Exception(result['message']);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject booking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _assignWorker(BookingModel booking) async {
    // Always load fresh available workers for the specific service type
    await _loadAvailableWorkers(serviceType: booking.serviceType);

    // Check if we found any available workers
    if (_availableWorkers.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No available workers found for ${booking.serviceDisplayName}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final workerId = await _showWorkerSelectionDialog(booking);
    if (workerId == null) return;

    try {
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      final result = await bookingProvider.assignWorker(booking.id, workerId);

      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Worker assigned successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(result['message']);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to assign worker: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _startWork(BookingModel booking) async {
    try {
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      final result = await bookingProvider.startWork(
        booking.id,
        workerNotes: 'Work started by admin',
      );

      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Work started successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(result['message']);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start work: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _completeWork(BookingModel booking) async {
    final amount = await _showCompleteWorkDialog(booking);
    if (amount == null) return;

    try {
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      final result = await bookingProvider.completeWork(
        booking.id,
        workerNotes: 'Work completed by admin',
        actualAmount: amount,
      );

      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Work completed successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(result['message']);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete work: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _showRejectDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject Booking'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Rejection Reason',
            hintText: 'Enter reason for rejection',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showWorkerSelectionDialog(BookingModel booking) async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Assign Worker'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Select a worker for ${booking.serviceDisplayName}:'),
            SizedBox(height: 16),
            ..._availableWorkers.map((worker) => ListTile(
              title: Text(worker['name'] ?? 'Unknown'),
              subtitle: Text('Phone: ${worker['phone'] ?? 'N/A'}'),
              onTap: () => Navigator.pop(context, worker['_id']),
            )).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<double?> _showCompleteWorkDialog(BookingModel booking) async {
    final controller = TextEditingController(
      text: booking.paymentAmount?.toString() ?? '0',
    );
    return showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Complete Work'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Final Amount (₹)',
            hintText: 'Enter final service amount',
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text.trim());
              Navigator.pop(context, amount);
            },
            child: Text('Complete'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'assigned':
        return Colors.purple;
      case 'in_progress':
        return Colors.indigo;
      case 'completed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}