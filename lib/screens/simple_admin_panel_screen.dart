import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/booking_provider.dart';
import '../providers/auth_provider.dart';
import '../models/booking_model.dart';

class SimpleAdminPanelScreen extends StatefulWidget {
  const SimpleAdminPanelScreen({Key? key}) : super(key: key);

  @override
  State<SimpleAdminPanelScreen> createState() => _SimpleAdminPanelScreenState();
}

class _SimpleAdminPanelScreenState extends State<SimpleAdminPanelScreen> {
  String _selectedFilter = 'all';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check authentication status
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      print('🔐 Current user: ${authProvider.user?.name ?? 'Not logged in'}');
      print('🔐 Is admin: ${authProvider.isAdmin}');

      if (authProvider.user == null) {
        throw Exception('User not logged in');
      }

      final bookingProvider =
          Provider.of<BookingProvider>(context, listen: false);
      await bookingProvider.fetchAllBookings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Loaded ${bookingProvider.adminBookings.length} bookings'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading bookings: $e'),
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

  List<BookingModel> _getFilteredBookings(List<BookingModel> allBookings) {
    if (_selectedFilter == 'all') {
      return allBookings;
    }
    return allBookings
        .where((booking) => booking.status == _selectedFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple Admin Panel'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBookings,
          ),
        ],
      ),
      body: Consumer<BookingProvider>(
        builder: (context, bookingProvider, child) {
          final allBookings = bookingProvider.adminBookings;
          final filteredBookings = _getFilteredBookings(allBookings);

          return Column(
            children: [
              // Dashboard Cards
              _buildDashboard(allBookings),

              // Filter Dropdown
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text('Filter: ',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedFilter,
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem(
                              value: 'all', child: Text('All Bookings')),
                          const DropdownMenuItem(
                              value: 'pending', child: Text('Pending')),
                          const DropdownMenuItem(
                              value: 'accepted', child: Text('Accepted')),
                          const DropdownMenuItem(
                              value: 'assigned', child: Text('Assigned')),
                          const DropdownMenuItem(
                              value: 'in_progress', child: Text('In Progress')),
                          const DropdownMenuItem(
                              value: 'completed', child: Text('Completed')),
                          const DropdownMenuItem(
                              value: 'rejected', child: Text('Rejected')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedFilter = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Debug Info
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Debug: ${allBookings.length} total, ${filteredBookings.length} filtered',
                  style: TextStyle(color: Colors.green[700], fontSize: 12),
                ),
              ),

              // Bookings List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredBookings.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _loadBookings,
                            child: Container(
                              color:
                                  Colors.white, // Add background color to debug
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: filteredBookings.length,
                                itemBuilder: (context, index) {
                                  return _buildBookingCard(
                                      filteredBookings[index]);
                                },
                              ),
                            ),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDashboard(List<BookingModel> bookings) {
    final statusCounts = <String, int>{};
    for (final booking in bookings) {
      statusCounts[booking.status] = (statusCounts[booking.status] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _buildDashboardCard(
                      'Total', bookings.length.toString(), Colors.blue)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildDashboardCard(
                      'Pending',
                      (statusCounts['pending'] ?? 0).toString(),
                      Colors.orange)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildDashboardCard(
                      'Active',
                      ((statusCounts['accepted'] ?? 0) +
                              (statusCounts['assigned'] ?? 0) +
                              (statusCounts['in_progress'] ?? 0))
                          .toString(),
                      Colors.purple)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildDashboardCard(
                      'Completed',
                      (statusCounts['completed'] ?? 0).toString(),
                      Colors.green)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(String title, String count, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _selectedFilter == 'all' ? Icons.inbox : Icons.filter_list_off,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == 'all'
                ? 'No bookings found'
                : 'No bookings match filter',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter == 'all'
                ? 'No bookings have been created yet'
                : 'No bookings with status: $_selectedFilter',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _selectedFilter == 'all'
                ? _loadBookings
                : () {
                    setState(() {
                      _selectedFilter = 'all';
                    });
                  },
            child: Text(_selectedFilter == 'all' ? 'Refresh' : 'Show All'),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    print(
        'Rendering booking card for: ${booking.customerName} - ${booking.serviceType}');
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      color: Colors.white,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking.serviceType.replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
                _buildStatusChip(booking.status),
              ],
            ),
            const SizedBox(height: 12),

            // Customer Info
            _buildInfoRow('Customer', booking.customerName),
            _buildInfoRow('Phone', booking.customerPhone),
            _buildInfoRow('Address', booking.customerAddress),
            _buildInfoRow('Date',
                '${booking.preferredDate.day}/${booking.preferredDate.month}/${booking.preferredDate.year}'),
            _buildInfoRow('Time', booking.preferredTime),
            if (booking.paymentAmount != null)
              _buildInfoRow('Amount', '₹${booking.paymentAmount}'),

            const SizedBox(height: 16),

            // Action Buttons
            _buildActionButtons(booking),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'accepted':
        color = Colors.blue;
        break;
      case 'assigned':
        color = Colors.purple;
        break;
      case 'in_progress':
        color = Colors.amber;
        break;
      case 'completed':
        color = Colors.green;
        break;
      case 'rejected':
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionButtons(BookingModel booking) {
    List<Widget> buttons = [];

    if (booking.status == 'pending') {
      buttons.addAll([
        Expanded(
          child: ElevatedButton(
            onPressed: () => _acceptBooking(booking),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Accept', style: TextStyle(color: Colors.white)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: () => _rejectBooking(booking),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ),
      ]);
    } else if (booking.status == 'accepted') {
      buttons.add(
        Expanded(
          child: ElevatedButton(
            onPressed: () => _assignWorker(booking),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            child: const Text('Assign Worker',
                style: TextStyle(color: Colors.white)),
          ),
        ),
      );
    } else if (booking.status == 'assigned') {
      buttons.add(
        Expanded(
          child: ElevatedButton(
            onPressed: () => _startWork(booking),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child:
                const Text('Start Work', style: TextStyle(color: Colors.white)),
          ),
        ),
      );
    } else if (booking.status == 'in_progress') {
      buttons.add(
        Expanded(
          child: ElevatedButton(
            onPressed: () => _completeWork(booking),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Complete Work',
                style: TextStyle(color: Colors.white)),
          ),
        ),
      );
    }

    return buttons.isEmpty ? const SizedBox.shrink() : Row(children: buttons);
  }

  Future<void> _acceptBooking(BookingModel booking) async {
    try {
      final bookingProvider =
          Provider.of<BookingProvider>(context, listen: false);
      final result = await bookingProvider.acceptBooking(booking.id,
          adminNotes: 'Accepted by admin');

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Booking accepted'), backgroundColor: Colors.green),
        );
        _loadBookings();
      } else {
        throw Exception(result['message']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _rejectBooking(BookingModel booking) async {
    try {
      final bookingProvider =
          Provider.of<BookingProvider>(context, listen: false);
      final result =
          await bookingProvider.rejectBooking(booking.id, 'Rejected by admin');

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Booking rejected'),
              backgroundColor: Colors.orange),
        );
        _loadBookings();
      } else {
        throw Exception(result['message']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _assignWorker(BookingModel booking) async {
    try {
      // Get available workers for this service type
      final bookingProvider =
          Provider.of<BookingProvider>(context, listen: false);
      final workers = await bookingProvider.getAvailableWorkers(
          serviceType: booking.serviceType);

      if (workers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No workers available for this service type'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Show worker selection dialog
      final selectedWorkerId = await _showWorkerSelectionDialog(workers);

      if (selectedWorkerId != null) {
        final result =
            await bookingProvider.assignWorker(booking.id, selectedWorkerId);

        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Worker assigned successfully'),
                backgroundColor: Colors.green),
          );
          _loadBookings();
        } else {
          throw Exception(result['message']);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error assigning worker: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  Future<String?> _showWorkerSelectionDialog(
      List<Map<String, dynamic>> workers) async {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Worker'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: workers.length,
              itemBuilder: (context, index) {
                final worker = workers[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.deepPurple,
                    child: Text(
                      worker['name']?.substring(0, 1).toUpperCase() ?? 'W',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(worker['name'] ?? 'Unknown Worker'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Phone: ${worker['phone'] ?? 'N/A'}'),
                      if (worker['skills'] != null)
                        Text(
                            'Skills: ${(worker['skills'] as List).join(', ')}'),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context).pop(worker['_id']);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _startWork(BookingModel booking) async {
    try {
      final bookingProvider =
          Provider.of<BookingProvider>(context, listen: false);
      final result = await bookingProvider.startWork(booking.id,
          workerNotes: 'Work started');

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Work started'), backgroundColor: Colors.green),
        );
        _loadBookings();
      } else {
        throw Exception(result['message']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _completeWork(BookingModel booking) async {
    try {
      final bookingProvider =
          Provider.of<BookingProvider>(context, listen: false);
      final result = await bookingProvider.completeWork(booking.id,
          workerNotes: 'Work completed');

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Work completed'), backgroundColor: Colors.green),
        );
        _loadBookings();
      } else {
        throw Exception(result['message']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
