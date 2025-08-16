import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../constants/app_constants.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../providers/notification_provider.dart';
import '../models/booking_model.dart';
import '../services/api_service.dart';
import '../services/service_completion_handler.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({Key? key}) : super(key: key);

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  io.Socket? socket;
  List bookings = []; // Your bookings list

  // Bulk operations state
  bool _isMultiSelectMode = false;
  Set<String> _selectedBookingIds = <String>{};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // First ensure admin is logged in
      await _ensureAdminLogin();

      final bookingProvider =
          Provider.of<BookingProvider>(context, listen: false);
      final notificationProvider =
          Provider.of<NotificationProvider>(context, listen: false);

      print('📱 Admin panel fetching bookings...');
      await bookingProvider.fetchAllBookings();
      print(
          '✅ Admin bookings fetched: ${bookingProvider.adminBookings.length}');

      await notificationProvider.fetchNotifications(refresh: true);

      // Set up periodic notification refresh
      _startNotificationPolling();
      connectToSocket();
    });
  }

  Future<void> _ensureAdminLogin() async {
    try {
      print('🔐 Ensuring admin is logged in...');
      final result = await ApiService.adminLogin(
        username: 'admin',
        password: 'admin123',
      );

      if (result['success'] == true) {
        print('✅ Admin login successful');
      } else {
        print('❌ Admin login failed: ${result['message']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Admin login failed: ${result['message']}')),
        );
      }
    } catch (e) {
      print('❌ Admin login error: $e');
    }
  }

  void _startNotificationPolling() {
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        final notificationProvider =
            Provider.of<NotificationProvider>(context, listen: false);
        notificationProvider.fetchUnreadCount();
        _startNotificationPolling();
      }
    });
  }

  void connectToSocket() {
    socket = io.io('http://10.0.2.2:5000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket!.onConnect((_) {
      print('Connected to Socket.IO server');
    });

    socket!.on('new_booking', (data) {
      // Show a notification or update your bookings list
      print('New booking received: $data');

      // Refresh the bookings list from the provider
      final bookingProvider =
          Provider.of<BookingProvider>(context, listen: false);
      bookingProvider.fetchAllBookings().then((_) {
        // Show a snackbar or dialog
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('New booking received! Refreshing data...')),
          );
        }
      });
    });

    socket!.onDisconnect((_) => print('Disconnected from Socket.IO server'));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    socket?.dispose();
    super.dispose();
  }

  // Filter bookings based on search and status
  List<BookingModel> _getFilteredBookings(List<BookingModel> bookings) {
    List<BookingModel> filtered = bookings;

    // Filter by status
    if (_selectedFilter != 'All') {
      String filterStatus;
      switch (_selectedFilter.toLowerCase()) {
        case 'pending':
          filterStatus = 'pending';
          break;
        case 'accepted':
          filterStatus = 'accepted';
          break;
        case 'completed':
          filterStatus = 'completed';
          break;
        case 'in progress':
          filterStatus = 'in_progress';
          break;
        case 'assigned':
          filterStatus = 'assigned';
          break;
        case 'rejected':
          filterStatus = 'rejected';
          break;
        case 'cancelled':
          filterStatus = 'cancelled';
          break;
        default:
          filterStatus = _selectedFilter.toLowerCase();
      }
      
      filtered =
          filtered.where((booking) => booking.status == filterStatus).toList();
    }

    // Filter by search query
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered
          .where((booking) =>
              booking.customerName.toLowerCase().contains(query) ||
              booking.customerPhone.contains(query) ||
              booking.serviceDisplayName.toLowerCase().contains(query))
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          // Notification Bell with Badge
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () => _showNotificationPanel(context),
                  ),
                  if (notificationProvider.unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${notificationProvider.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              final bookingProvider =
                  Provider.of<BookingProvider>(context, listen: false);
              final notificationProvider =
                  Provider.of<NotificationProvider>(context, listen: false);

              await bookingProvider.fetchAllBookings();
              await notificationProvider.fetchNotifications(refresh: true);
            },
          ),

          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              Navigator.pushNamed(context, '/admin-payment-verification');
            },
            tooltip: 'Verify QR Payments',
          ),

          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showLogoutDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Dashboard', icon: Icon(Icons.dashboard)),
            Tab(text: 'Bookings', icon: Icon(Icons.book_online)),
            Tab(text: 'Payments', icon: Icon(Icons.payment)),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildDashboardTab(),
            _buildBookingsTab(),
            _buildPaymentsTab(),
          ],
        ),
      ),
      floatingActionButton: _buildWorkerManagementFAB(),
    );
  }

  // Dashboard Tab
  Widget _buildDashboardTab() {
    return Consumer<BookingProvider>(
      builder: (context, bookingProvider, child) {
        final bookings = bookingProvider.adminBookings;

        return RefreshIndicator(
          onRefresh: () => bookingProvider.fetchAllBookings(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Welcome Section with Real-time Stats
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.deepPurple[100]!, Colors.blue[50]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome, Admin!',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple[800],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Manage your service bookings and operations',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[700],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Real-time indicator
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Live',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Quick Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickActionButton(
                              'Accept All Pending',
                              Icons.check_circle_outline,
                              Colors.green,
                              () => _bulkAcceptPendingBookings(),
                              enabled: bookingProvider
                                  .getPendingBookings()
                                  .isNotEmpty,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildQuickActionButton(
                              'View Urgent',
                              Icons.priority_high,
                              Colors.red,
                              () => _showUrgentBookings(),
                              enabled: _getUrgentBookings(bookings).isNotEmpty,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Enhanced Stats Cards with Real-time Metrics
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Real-time Metrics',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      'Updated: ${DateFormat('HH:mm').format(DateTime.now())}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: [
                    _buildEnhancedStatCard(
                      'Total Bookings',
                      bookings.length.toString(),
                      Icons.book_online,
                      Colors.blue,
                      subtitle: 'All time',
                      onTap: () => _tabController.animateTo(1),
                    ),
                    _buildEnhancedStatCard(
                      'Pending',
                      bookingProvider
                          .getBookingCountByStatus(AppConstants.pending)
                          .toString(),
                      Icons.schedule,
                      Colors.orange,
                      subtitle: 'Needs attention',
                      onTap: () => _showFilteredBookings('pending'),
                    ),
                    _buildEnhancedStatCard(
                      'In Progress',
                      bookingProvider
                          .getBookingCountByStatus(AppConstants.inProgress)
                          .toString(),
                      Icons.build,
                      Colors.indigo,
                      subtitle: 'Active services',
                      onTap: () => _showFilteredBookings('in_progress'),
                    ),
                    _buildEnhancedStatCard(
                      'Completed Today',
                      _getTodayCompletedCount(bookings).toString(),
                      Icons.check_circle,
                      Colors.green,
                      subtitle: 'Today\'s success',
                      onTap: () => _showTodayCompletedBookings(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Revenue and Performance Metrics
                Row(
                  children: [
                    Expanded(
                      child: _buildRevenueCard(bookings),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildPerformanceCard(bookings),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Priority Bookings Section
                if (_getUrgentBookings(bookings).isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.priority_high,
                          color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Urgent Bookings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _showUrgentBookings(),
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._getUrgentBookings(bookings)
                      .take(3)
                      .map((booking) => _buildUrgentBookingCard(booking))
                      .toList(),
                  const SizedBox(height: 20),
                ],

                // Recent Bookings with Enhanced Display
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Recent Bookings',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.sort),
                      onPressed: () => _showSortOptions(),
                      tooltip: 'Sort options',
                    ),
                    TextButton(
                      onPressed: () => _tabController.animateTo(1),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (bookings.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.book_online,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No bookings yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  ...bookings
                      .take(5)
                      .map((booking) => _buildEnhancedBookingCard(booking))
                      .toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  // Bookings Tab
  Widget _buildBookingsTab() {
    return Consumer<BookingProvider>(
      builder: (context, bookingProvider, child) {
        if (bookingProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final allBookings = bookingProvider.adminBookings;
        final filteredBookings = _getFilteredBookings(allBookings);

        return Column(
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by customer name, phone, or service...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),

            // Filter Tabs
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', allBookings.length,
                        isSelected: _selectedFilter == 'All'),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                        'Pending',
                        bookingProvider
                            .getBookingCountByStatus(AppConstants.pending),
                        isSelected: _selectedFilter == 'Pending'),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                        'Accepted',
                        bookingProvider
                            .getBookingCountByStatus(AppConstants.accepted),
                        isSelected: _selectedFilter == 'Accepted'),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                        'Completed',
                        bookingProvider
                            .getBookingCountByStatus(AppConstants.completed),
                        isSelected: _selectedFilter == 'Completed'),
                  ],
                ),
              ),
            ),

            // Bulk Operations Bar
            if (_isMultiSelectMode) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.blue[50],
                child: Row(
                  children: [
                    Text(
                      '${_selectedBookingIds.length} selected',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _selectedBookingIds.isEmpty
                          ? null
                          : _bulkAcceptSelected,
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Accept'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: _selectedBookingIds.isEmpty
                          ? null
                          : _bulkRejectSelected,
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Reject'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _exitMultiSelectMode,
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Multi-select toggle button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${filteredBookings.length} bookings',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: filteredBookings.isEmpty
                          ? null
                          : _enterMultiSelectMode,
                      icon: const Icon(Icons.checklist, size: 16),
                      label: const Text('Select'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),

            // Bookings List
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => bookingProvider.fetchAllBookings(),
                child: filteredBookings.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.book_online,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No bookings found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredBookings.length,
                        itemBuilder: (context, index) {
                          final booking = filteredBookings[index];
                          final isSelected =
                              _selectedBookingIds.contains(booking.id);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: isSelected ? 4 : 1,
                            color: isSelected ? Colors.blue[50] : null,
                            child: InkWell(
                              onTap: () => _isMultiSelectMode
                                  ? _toggleBookingSelection(booking.id)
                                  : _showBookingDetails(booking),
                              onLongPress: () => _isMultiSelectMode
                                  ? null
                                  : _enterMultiSelectModeWithSelection(
                                      booking.id),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        // Multi-select checkbox
                                        if (_isMultiSelectMode) ...[
                                          Checkbox(
                                            value: isSelected,
                                            onChanged: (value) =>
                                                _toggleBookingSelection(
                                                    booking.id),
                                            activeColor: Colors.deepPurple,
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        Expanded(
                                          child: Text(
                                            booking.serviceDisplayName,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color:
                                                _getStatusColor(booking.status),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            booking.statusDisplayName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Customer: ${booking.customerName}',
                                      style: TextStyle(color: Colors.grey[700]),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    Text(
                                      'Phone: ${booking.customerPhone}',
                                      style: TextStyle(color: Colors.grey[700]),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    Text(
                                      'Date: ${DateFormat('dd MMM yyyy').format(booking.preferredDate)} at ${booking.preferredTime}',
                                      style: TextStyle(color: Colors.grey[700]),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    if (booking.description?.isNotEmpty ==
                                        true) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Issue: ${booking.description}',
                                        style:
                                            TextStyle(color: Colors.grey[600]),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Amount: ₹${booking.paymentAmount?.toInt() ?? 0}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green[600],
                                            ),
                                          ),
                                        ),
                                        Text(
                                          'Booked: ${DateFormat('dd MMM').format(booking.createdAt)}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    _buildWorkflowActionButtons(booking),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWorkflowActionButtons(BookingModel booking) {
    List<Widget> buttons = [];

    if (booking.status == AppConstants.pending) {
      buttons.add(_buildActionButton(
          'Accept', () => _acceptBooking(booking), Colors.green));
    }

    if (booking.status == AppConstants.accepted) {
      buttons.add(_buildActionButton(
          'Assign Worker', () => _assignWorker(booking), Colors.blue));
    }

    if (booking.status == AppConstants.assigned) {
      buttons.add(_buildActionButton(
          'Start Service', () => _startService(booking), Colors.orange));
    }

    if (booking.status == AppConstants.inProgress) {
      buttons.add(_buildActionButton(
          'Complete', () => _completeService(booking), Colors.purple));
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: buttons,
    );
  }

  Widget _buildActionButton(String text, VoidCallback onPressed, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        child: Text(text, style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  void _acceptBooking(BookingModel booking) async {
    try {
      final bookingProvider =
          Provider.of<BookingProvider>(context, listen: false);
      final result = await bookingProvider.acceptBooking(
        booking.id,
        adminNotes: 'Booking accepted by admin',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Booking accepted successfully'),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to accept booking: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _assignWorker(BookingModel booking) {
    showDialog(
      context: context,
      builder: (context) => _buildWorkerAssignmentDialog(booking),
    );
  }

  Widget _buildWorkerAssignmentDialog(BookingModel booking) {
    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: const Text('Assign Worker'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Service: ${booking.serviceDisplayName}'),
              Text('Customer: ${booking.customerName}'),
              const SizedBox(height: 16),
              const Text('Available Workers:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                height: 200,
                width: double.maxFinite,
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _getAvailableWorkers(booking.serviceType),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text('No available workers found'),
                      );
                    }
                    
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final worker = snapshot.data![index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(worker['name'][0].toUpperCase()),
                            ),
                            title: Text(worker['name']),
                            subtitle: Text('Phone: ${worker['phone']}'),
                            trailing: ElevatedButton(
                              onPressed: () =>
                                  _confirmWorkerAssignment(booking, worker),
                              child: const Text('Assign'),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getAvailableWorkers(
      String serviceType) async {
    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);
    return await bookingProvider.getAvailableWorkers(serviceType: serviceType);
  }

  void _confirmWorkerAssignment(
      BookingModel booking, Map<String, dynamic> worker) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Assignment'),
        content: Text(
            'Assign ${worker['name']} to ${booking.customerName}\'s ${booking.serviceDisplayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close confirmation dialog
              Navigator.pop(context); // Close worker selection dialog
              
              final bookingProvider =
                  Provider.of<BookingProvider>(context, listen: false);
              final result =
                  await bookingProvider.assignWorker(booking.id, worker['_id']);
              
              if (!mounted) return;
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text(result['message'] ?? 'Worker assigned successfully'),
                  backgroundColor:
                      result['success'] ? Colors.green : Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Confirm Assignment'),
          ),
        ],
      ),
    );
  }

  void _startService(BookingModel booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Service'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Start service for ${booking.customerName}?'),
            const SizedBox(height: 8),
            Text(
                'Worker: ${booking.assignedEmployeeName ?? 'Assigned Worker'}'),
            Text('Service: ${booking.serviceDisplayName}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final bookingProvider =
                  Provider.of<BookingProvider>(context, listen: false);
              
              final result = await bookingProvider.startWork(booking.id);
              
              if (!mounted) return;
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text(result['message'] ?? 'Service started successfully'),
                  backgroundColor:
                      result['success'] ? Colors.green : Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Start Service'),
          ),
        ],
      ),
    );
  }

  void _completeService(BookingModel booking) {
    final amountController = TextEditingController(
      text: booking.paymentAmount?.toString() ?? '0',
    );
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Service'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Complete service for ${booking.customerName}?'),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Final Amount (₹) *',
                  hintText: 'Enter the amount customer needs to pay',
                  border: OutlineInputBorder(),
                  prefixText: '₹ ',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Work Notes (Optional)',
                  hintText: 'Any notes about the completed work...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What happens next:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text('• Customer will be notified to make payment'),
                    Text('• Payment screen will open for customer'),
                    Text('• Service marked as completed'),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (amountController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter the payment amount'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final amount = double.tryParse(amountController.text.trim());
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid amount'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context);
              final bookingProvider =
                  Provider.of<BookingProvider>(context, listen: false);
              
              final result = await bookingProvider.completeWork(
                booking.id,
                workerNotes: notesController.text.trim().isNotEmpty 
                    ? notesController.text.trim() 
                    : null,
                actualAmount: amount,
              );
              
              if (!mounted) return;
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      result['message'] ?? 'Service completed successfully'),
                  backgroundColor:
                      result['success'] ? Colors.green : Colors.red,
                ),
              );

              if (result['success']) {
                // Show payment notification dialog
                _showPaymentNotificationDialog(booking, amount);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Complete & Request Payment'),
          ),
        ],
      ),
    );
  }

  void _showPaymentNotificationDialog(BookingModel booking, double amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 24),
            const SizedBox(width: 8),
            const Text('Service Completed!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Service completed for ${booking.customerName}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Amount: ₹${amount.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                children: [
                  Icon(Icons.notifications_active,
                      color: Colors.blue, size: 32),
                  SizedBox(height: 8),
                  Text(
                    'Customer has been notified to make payment',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

// Payments Tab
  Widget _buildPaymentsTab() {
    return Consumer<BookingProvider>(
      builder: (context, bookingProvider, child) {
        final completedBookings = bookingProvider.adminBookings
            .where((booking) => booking.status == AppConstants.completed)
            .toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Payment Management',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Payment Stats
              Row(
                children: [
                  Expanded(
                    child: _buildPaymentStatCard(
                      'Total Revenue',
                      '₹${_calculateRevenue(completedBookings)}',
                      Icons.monetization_on,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildPaymentStatCard(
                      'Completed Services',
                      completedBookings.length.toString(),
                      Icons.check_circle,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Completed Bookings List
              const Text(
                'Completed Services',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              if (completedBookings.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.payment,
                            size: 48,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No completed services yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ...completedBookings
                    .map((booking) => Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green,
                              child: const Icon(
                                Icons.check_circle,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              booking.serviceDisplayName,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Customer: ${booking.customerName}',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                Text(
                                  'Payment: ${booking.paymentMethodDisplayName}',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                if (booking.completedDate != null)
                                  Text(
                                    'Completed: ${DateFormat('dd MMM yyyy, hh:mm a').format(booking.completedDate!)}',
                                  ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${booking.paymentAmount?.toInt() ?? 0}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: booking.isPaid
                                        ? Colors.green
                                        : Colors.orange,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    booking.isPaid ? 'PAID' : 'PENDING',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              if (!booking.isPaid) {
                                _showPaymentConfirmation(booking);
                              }
                            },
                          ),
                        ))
                    .toList(),
            ],
          ),
        );
      },
    );
  }

// Helper Methods
  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Enhanced stat card with tap functionality and subtitle
  Widget _buildEnhancedStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Quick action button
  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed, {
    bool enabled = true,
  }) {
    return ElevatedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: enabled ? color : Colors.grey,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // Revenue card
  Widget _buildRevenueCard(List<dynamic> bookings) {
    final totalRevenue = _calculateRevenue(bookings);
    final todayRevenue = _calculateTodayRevenue(bookings);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.monetization_on, color: Colors.green[600], size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Revenue',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '₹$totalRevenue',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Total Revenue',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Today: ₹$todayRevenue',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.green[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Performance card
  Widget _buildPerformanceCard(List<dynamic> bookings) {
    final completionRate = _calculateCompletionRate(bookings);
    final avgResponseTime = _calculateAvgResponseTime(bookings);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.blue[600], size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Performance',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${completionRate.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Completion Rate',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Avg Response: ${avgResponseTime}h',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.blue[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Enhanced booking card
  Widget _buildEnhancedBookingCard(dynamic booking) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showBookingDetails(booking),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: _getStatusColor(booking.status),
                          radius: 16,
                          child: Icon(
                            _getStatusIcon(booking.status),
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                booking.serviceDisplayName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                booking.customerName,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(booking.status),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          booking.statusDisplayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${booking.paymentAmount?.toInt() ?? 0}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd MMM, HH:mm').format(booking.preferredDate),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  if (_isUrgentBooking(booking))
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.priority_high,
                              size: 12, color: Colors.red[700]),
                          const SizedBox(width: 2),
                          Text(
                            'URGENT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              if (booking.status == AppConstants.pending) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _acceptBooking(booking),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Accept',
                            style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _rejectBooking(booking),
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Reject',
                            style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Urgent booking card
  Widget _buildUrgentBookingCard(dynamic booking) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.red[50],
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.red,
          child: const Icon(Icons.priority_high, color: Colors.white, size: 20),
        ),
        title: Text(
          booking.serviceDisplayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${booking.customerName} • ${_getUrgencyReason(booking)}',
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        trailing: ElevatedButton(
          onPressed: () => _showBookingDetails(booking),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          ),
          child: const Text('Handle', style: TextStyle(fontSize: 12)),
        ),
      ),
    );
  }

  Widget _buildPaymentStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int count, {bool isSelected = false}) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Chip(
        label: Text('$label ($count)'),
        backgroundColor: isSelected ? Colors.deepPurple : Colors.grey[100],
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'accepted':
        return Icons.thumb_up;
      case 'assigned':
        return Icons.person;
      case 'in_progress':
        return Icons.build;
      case 'completed':
        return Icons.check_circle;
      case 'rejected':
        return Icons.thumb_down;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _calculateRevenue(List<dynamic> bookings) {
    double total = 0;
    for (var booking in bookings) {
      if (booking.paymentAmount != null &&
          booking.status == AppConstants.completed) {
        total += booking.paymentAmount!;
      }
    }
    return total.toInt().toString();
  }

  // Calculate today's revenue
  String _calculateTodayRevenue(List<dynamic> bookings) {
    double total = 0;
    final today = DateTime.now();
    for (var booking in bookings) {
      if (booking.paymentAmount != null &&
          booking.status == AppConstants.completed &&
          booking.completedDate != null &&
          _isSameDay(booking.completedDate!, today)) {
        total += booking.paymentAmount!;
      }
    }
    return total.toInt().toString();
  }

  // Calculate completion rate
  double _calculateCompletionRate(List<dynamic> bookings) {
    if (bookings.isEmpty) return 0.0;
    final completedCount =
        bookings.where((b) => b.status == AppConstants.completed).length;
    return (completedCount / bookings.length) * 100;
  }

  // Calculate average response time
  String _calculateAvgResponseTime(List<dynamic> bookings) {
    final acceptedBookings = bookings
        .where((b) => b.acceptedDate != null && b.createdAt != null)
        .toList();

    if (acceptedBookings.isEmpty) return '0';

    double totalHours = 0;
    for (var booking in acceptedBookings) {
      final diff = booking.acceptedDate!.difference(booking.createdAt).inHours;
      totalHours += diff;
    }

    return (totalHours / acceptedBookings.length).toStringAsFixed(1);
  }

  // Get today's completed bookings count
  int _getTodayCompletedCount(List<dynamic> bookings) {
    final today = DateTime.now();
    return bookings
        .where((booking) =>
            booking.status == AppConstants.completed &&
            booking.completedDate != null &&
            _isSameDay(booking.completedDate!, today))
        .length;
  }

  // Get urgent bookings
  List<dynamic> _getUrgentBookings(List<dynamic> bookings) {
    return bookings.where((booking) => _isUrgentBooking(booking)).toList();
  }

  // Check if booking is urgent
  bool _isUrgentBooking(dynamic booking) {
    if (booking.status == AppConstants.pending) {
      final hoursSinceCreated =
          DateTime.now().difference(booking.createdAt).inHours;
      return hoursSinceCreated > 2; // Pending for more than 2 hours
    }
    if (booking.status == AppConstants.accepted) {
      final hoursSinceAccepted = booking.acceptedDate != null
          ? DateTime.now().difference(booking.acceptedDate!).inHours
          : 0;
      return hoursSinceAccepted >
          4; // Accepted but not assigned for more than 4 hours
    }
    return false;
  }

  // Get urgency reason
  String _getUrgencyReason(dynamic booking) {
    if (booking.status == AppConstants.pending) {
      final hoursSinceCreated =
          DateTime.now().difference(booking.createdAt).inHours;
      return 'Pending for ${hoursSinceCreated}h';
    }
    if (booking.status == AppConstants.accepted) {
      final hoursSinceAccepted = booking.acceptedDate != null
          ? DateTime.now().difference(booking.acceptedDate!).inHours
          : 0;
      return 'Not assigned for ${hoursSinceAccepted}h';
    }
    return 'Needs attention';
  }

  // Check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Dialog Functions
  void _showBookingDetails(booking) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.95,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Column(
            children: [
              // Enhanced Header with Status and Actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getStatusColor(booking.status),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(_getStatusIcon(booking.status),
                            color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Booking Details',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'ID: ${booking.id.substring(0, 8)}...',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Quick actions in header
                        if (booking.status == AppConstants.pending) ...[
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.white),
                            onPressed: () {
                              Navigator.pop(context);
                              _acceptBooking(booking);
                            },
                            tooltip: 'Quick Accept',
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () {
                              Navigator.pop(context);
                              _rejectBooking(booking);
                            },
                            tooltip: 'Quick Reject',
                          ),
                        ],
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Status timeline indicator
                    _buildStatusTimeline(booking),
                  ],
                ),
              ),

              // Content with Tabs
              Expanded(
                child: DefaultTabController(
                  length: 4,
                  child: Column(
                    children: [
                      const TabBar(
                        labelColor: Colors.deepPurple,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Colors.deepPurple,
                        tabs: [
                          Tab(
                              text: 'Details',
                              icon: Icon(Icons.info, size: 16)),
                          Tab(
                              text: 'History',
                              icon: Icon(Icons.history, size: 16)),
                          Tab(text: 'Notes', icon: Icon(Icons.note, size: 16)),
                          Tab(
                              text: 'Actions',
                              icon: Icon(Icons.build, size: 16)),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildDetailsTab(booking),
                            _buildHistoryTab(booking),
                            _buildNotesTab(booking),
                            _buildActionsTab(booking),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  // Status timeline widget
  Widget _buildStatusTimeline(dynamic booking) {
    final statuses = [
      'pending',
      'accepted',
      'assigned',
      'in_progress',
      'completed'
    ];
    final currentIndex = statuses.indexOf(booking.status);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: statuses.asMap().entries.map((entry) {
          final index = entry.key;
          final status = entry.value;
          final isActive = index <= currentIndex;
          final isCurrent = index == currentIndex;

          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white : Colors.white30,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCurrent ? Colors.white : Colors.white30,
                      width: 2,
                    ),
                  ),
                  child: isActive
                      ? Icon(
                          isCurrent ? Icons.radio_button_checked : Icons.check,
                          size: 12,
                          color: _getStatusColor(booking.status),
                        )
                      : null,
                ),
                if (index < statuses.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isActive ? Colors.white : Colors.white30,
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // Details tab
  Widget _buildDetailsTab(dynamic booking) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service Information
          _buildDetailSection('Service Information', [
            _buildDetailRow('Service Type', booking.serviceDisplayName),
            _buildDetailRow('Status', booking.statusDisplayName),
            _buildDetailRow('Payment Method', booking.paymentMethodDisplayName),
            _buildDetailRow(
                'Amount', '₹${booking.paymentAmount?.toInt() ?? 0}'),
            if (booking.actualAmount != null)
              _buildDetailRow(
                  'Actual Amount', '₹${booking.actualAmount!.toInt()}'),
          ]),

          const SizedBox(height: 16),

          // Customer Information
          _buildDetailSection('Customer Information', [
            _buildDetailRow('Name', booking.customerName),
            _buildDetailRow('Phone', booking.customerPhone),
            _buildDetailRow('Address', booking.customerAddress),
            _buildDetailRow('Preferred Date',
                DateFormat('dd MMM yyyy').format(booking.preferredDate)),
            _buildDetailRow('Preferred Time', booking.preferredTime),
          ]),

          if (booking.description?.isNotEmpty == true) ...[
            const SizedBox(height: 16),
            _buildDetailSection('Issue Description', [
              Text(booking.description!, style: const TextStyle(fontSize: 14)),
            ]),
          ],

          // Worker Information
          if (booking.assignedEmployee != null) ...[
            const SizedBox(height: 16),
            _buildDetailSection('Assigned Worker', [
              _buildDetailRow(
                  'Worker', booking.assignedEmployee?.name ?? 'Not assigned'),
              if (booking.assignedEmployee?.phone != null)
                _buildDetailRow('Phone', booking.assignedEmployee!.phone),
              if (booking.assignedDate != null)
                _buildDetailRow(
                    'Assigned Date',
                    DateFormat('dd MMM yyyy, HH:mm')
                        .format(booking.assignedDate!)),
            ]),
          ],
        ],
      ),
    );
  }

  // History tab
  Widget _buildHistoryTab(dynamic booking) {
    final historyItems = <Map<String, dynamic>>[];

    // Add booking creation
    historyItems.add({
      'title': 'Booking Created',
      'subtitle': 'Customer created the booking request',
      'time': booking.createdAt,
      'icon': Icons.add_circle,
      'color': Colors.blue,
    });

    // Add acceptance
    if (booking.acceptedDate != null) {
      historyItems.add({
        'title': 'Booking Accepted',
        'subtitle': 'Admin accepted the booking request',
        'time': booking.acceptedDate,
        'icon': Icons.check_circle,
        'color': Colors.green,
      });
    }

    // Add rejection
    if (booking.rejectedDate != null) {
      historyItems.add({
        'title': 'Booking Rejected',
        'subtitle':
            'Reason: ${booking.rejectionReason ?? 'No reason provided'}',
        'time': booking.rejectedDate,
        'icon': Icons.cancel,
        'color': Colors.red,
      });
    }

    // Add worker assignment
    if (booking.assignedDate != null) {
      historyItems.add({
        'title': 'Worker Assigned',
        'subtitle': 'Worker: ${booking.assignedEmployee?.name ?? 'Unknown'}',
        'time': booking.assignedDate,
        'icon': Icons.person_add,
        'color': Colors.purple,
      });
    }

    // Add service start
    if (booking.startedDate != null) {
      historyItems.add({
        'title': 'Service Started',
        'subtitle': 'Worker started the service',
        'time': booking.startedDate,
        'icon': Icons.play_circle,
        'color': Colors.orange,
      });
    }

    // Add completion
    if (booking.completedDate != null) {
      historyItems.add({
        'title': 'Service Completed',
        'subtitle': 'Service completed successfully',
        'time': booking.completedDate,
        'icon': Icons.check_circle_outline,
        'color': Colors.green,
      });
    }

    // Sort by time
    historyItems.sort(
        (a, b) => (a['time'] as DateTime).compareTo(b['time'] as DateTime));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: historyItems.length,
      itemBuilder: (context, index) {
        final item = historyItems[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: item['color'],
              child: Icon(item['icon'], color: Colors.white, size: 20),
            ),
            title: Text(
              item['title'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['subtitle']),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd MMM yyyy, HH:mm').format(item['time']),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Notes tab
  Widget _buildNotesTab(dynamic booking) {
    final adminNotesController =
        TextEditingController(text: booking.adminNotes ?? '');
    final workerNotesController =
        TextEditingController(text: booking.workerNotes ?? '');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Admin Notes
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.admin_panel_settings,
                          color: Colors.deepPurple),
                      const SizedBox(width: 8),
                      const Text(
                        'Admin Notes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: adminNotesController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Add admin notes here...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () =>
                        _saveAdminNotes(booking, adminNotesController.text),
                    icon: const Icon(Icons.save, size: 16),
                    label: const Text('Save Notes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Worker Notes (Read-only)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.build, color: Colors.orange),
                      const SizedBox(width: 8),
                      const Text(
                        'Worker Notes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      booking.workerNotes?.isNotEmpty == true
                          ? booking.workerNotes!
                          : 'No worker notes yet',
                      style: TextStyle(
                        color: booking.workerNotes?.isNotEmpty == true
                            ? Colors.black87
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Communication History
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.chat, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Text(
                        'Communication History',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => _addCommunicationEntry(booking),
                        icon: const Icon(Icons.add_comment, size: 20),
                        tooltip: 'Add Communication Entry',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildCommunicationHistory(booking),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Actions tab
  Widget _buildActionsTab(dynamic booking) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Status-specific actions
          if (booking.status == AppConstants.pending) ...[
            _buildActionCard(
              'Accept Booking',
              'Accept this booking request',
              Icons.check_circle,
              Colors.green,
              () {
                Navigator.pop(context);
                _acceptBooking(booking);
              },
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              'Reject Booking',
              'Reject this booking request',
              Icons.cancel,
              Colors.red,
              () {
                Navigator.pop(context);
                _rejectBooking(booking);
              },
            ),
          ] else if (booking.status == AppConstants.accepted) ...[
            _buildActionCard(
              'Assign Worker',
              'Assign a worker to this booking',
              Icons.person_add,
              Colors.blue,
              () {
                Navigator.pop(context);
                _showWorkerAssignmentDialog(booking);
              },
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              'Mark as Completed',
              'Mark service as completed',
              Icons.check_circle_outline,
              Colors.green,
              () {
                Navigator.pop(context);
                _completeService(booking);
              },
            ),
          ] else if (booking.status == AppConstants.completed &&
              !booking.isPaid) ...[
            _buildActionCard(
              'Process Payment',
              'Process payment for completed service',
              Icons.payment,
              Colors.purple,
              () {
                Navigator.pop(context);
                _showPaymentConfirmation(booking);
              },
            ),
          ],

          const SizedBox(height: 20),

          // General actions
          const Text(
            'General Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          _buildActionCard(
            'Contact Customer',
            'Call or message the customer',
            Icons.phone,
            Colors.orange,
            () => _contactCustomer(booking),
          ),
          const SizedBox(height: 12),

          _buildActionCard(
            'View Location',
            'View customer location on map',
            Icons.location_on,
            Colors.indigo,
            () => _viewLocation(booking),
          ),
          const SizedBox(height: 12),

          _buildActionCard(
            'Print Details',
            'Print booking details',
            Icons.print,
            Colors.grey,
            () => _printBookingDetails(booking),
          ),
        ],
      ),
    );
  }

  // Action card widget
  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(booking) {
    return Consumer<BookingProvider>(
      builder: (context, bookingProvider, child) {
        if (bookingProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        List<Widget> buttons = [];

        // Pending status - can accept or reject
        if (booking.status == AppConstants.pending) {
          buttons.addAll([
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _acceptBooking(booking),
                icon: const Icon(Icons.check),
                label: const Text('Accept'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _rejectBooking(booking),
                icon: const Icon(Icons.close),
                label: const Text('Reject'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ]);
        }

        // Accepted status - can assign worker or mark as completed
        else if (booking.status == AppConstants.accepted) {
          buttons.addAll([
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog first
                  _showWorkerAssignmentDialog(booking);
                },
                icon: const Icon(Icons.assignment_ind),
                label: const Text('Assign Worker'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _completeService(booking),
                icon: const Icon(Icons.check_circle),
                label: const Text('Complete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ]);
        }

        // Completed status - can process payment
        else if (booking.status == AppConstants.completed && !booking.isPaid) {
          buttons.add(
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showPaymentConfirmation(booking),
                icon: const Icon(Icons.payment),
                label: const Text('Process Payment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          );
        }

        // If no specific actions, show close button
        if (buttons.isEmpty) {
          buttons.add(
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                label: const Text('Close'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          );
        }

        return Row(children: buttons);
      },
    );
  }

  // Accept Booking (duplicate removed)

  // Reject Booking
  void _rejectBooking(booking) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reject booking for ${booking.customerName}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason *',
                hintText: 'Please provide reason for rejection...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide rejection reason'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context);
              final bookingProvider =
                  Provider.of<BookingProvider>(context, listen: false);

              final result = await bookingProvider.rejectBooking(
                booking.id,
                reasonController.text.trim(),
              );

              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result['message'] ?? 'Booking rejected'),
                  backgroundColor:
                      result['success'] ? Colors.orange : Colors.red,
                ),
              );

              if (result['success']) {
                Navigator.pop(context); // Close booking details
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  // Complete Service (duplicate removed)

  // Trigger automatic payment navigation for user
  void _triggerUserPaymentNavigation(booking) {
    // Import the service completion handler at the top of the file
    // This will trigger the WebSocket notification and automatic navigation
    ServiceCompletionHandler.handleServiceCompletion(
      booking: booking,
    );
  }

  // Show Payment Screen
  void _showPaymentScreen(booking) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Payment Processing'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Service completed for ${booking.customerName}!',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please process the payment now.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showPaymentConfirmation(booking);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Process Payment',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Show Payment Confirmation
  void _showPaymentConfirmation(booking) {
    Navigator.pushNamed(
      context,
      '/payment-confirmation',
      arguments: {'booking': booking},
    );
  }

  // Notification Panel
  void _showNotificationPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Consumer<NotificationProvider>(
                    builder: (context, notificationProvider, child) {
                      return TextButton(
                        onPressed: notificationProvider.unreadCount > 0
                            ? () => notificationProvider.markAllAsRead()
                            : null,
                        child: Text(
                          'Mark All Read',
                          style: TextStyle(
                            color: notificationProvider.unreadCount > 0
                                ? Colors.white
                                : Colors.white54,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            // Notifications List
            Expanded(
              child: Consumer<NotificationProvider>(
                builder: (context, notificationProvider, child) {
                  if (notificationProvider.isLoading &&
                      notificationProvider.notifications.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (notificationProvider.notifications.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No notifications yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () =>
                        notificationProvider.fetchNotifications(refresh: true),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: notificationProvider.notifications.length,
                      itemBuilder: (context, index) {
                        final notification =
                            notificationProvider.notifications[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: notification.isRead
                              ? Colors.white
                              : Colors.blue[50],
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  _getNotificationColor(notification.type),
                              child: Icon(
                                _getNotificationIcon(notification.type),
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: notification.isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(notification.message),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('dd MMM yyyy, hh:mm a')
                                      .format(notification.createdAt),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            trailing: notification.priority == 'high'
                                ? const Icon(Icons.priority_high,
                                    color: Colors.red)
                                : null,
                            onTap: () {
                              if (!notification.isRead) {
                                notificationProvider
                                    .markAsRead(notification.id);
                              }
                              // Handle notification tap (e.g., navigate to booking details)
                              if (notification.relatedBookingId != null) {
                                Navigator.pop(context);
                                // Navigate to booking details or switch to bookings tab
                                _tabController.animateTo(1);
                              }
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'booking':
        return Colors.blue;
      case 'payment':
        return Colors.green;
      case 'system':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'booking':
        return Icons.book_online;
      case 'payment':
        return Icons.payment;
      case 'system':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content:
            const Text('Are you sure you want to logout from admin panel?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
              if (!mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  // Worker Management FAB
  Widget _buildWorkerManagementFAB() {
    return FloatingActionButton(
      onPressed: () => _showWorkerManagementMenu(),
      backgroundColor: Colors.deepPurple,
      child: const Icon(Icons.people, color: Colors.white),
      tooltip: 'Worker Management',
    );
  }

  void _showWorkerManagementMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Worker Management',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(Icons.assignment_ind, color: Colors.white),
              ),
              title: const Text('Assign Workers'),
              subtitle: const Text('Assign workers to bookings'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pop(context);
                _navigateToWorkerAssignment();
              },
            ),
            const Divider(),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.analytics, color: Colors.white),
              ),
              title: const Text('Worker Performance'),
              subtitle: const Text('View worker statistics and metrics'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pop(context);
                _showWorkerPerformanceDialog();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _navigateToWorkerAssignment() {
    // Show dialog to select a booking first
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Booking'),
        content: const Text(
          'Please select a booking from the Bookings tab to assign a worker.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _tabController.animateTo(1); // Switch to bookings tab
            },
            child: const Text('Go to Bookings'),
          ),
        ],
      ),
    );
  }

  // Bulk accept pending bookings
  void _bulkAcceptPendingBookings() {
    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);
    final pendingBookings = bookingProvider.getPendingBookings();

    if (pendingBookings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pending bookings to accept'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Accept Bookings'),
        content: Text('Accept all ${pendingBookings.length} pending bookings?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              // Show progress dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const AlertDialog(
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Accepting bookings...'),
                    ],
                  ),
                ),
              );

              int successCount = 0;
              for (var booking in pendingBookings) {
                final result = await bookingProvider.acceptBooking(booking.id);
                if (result['success']) successCount++;
              }

              Navigator.pop(context); // Close progress dialog

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Successfully accepted $successCount bookings'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Accept All'),
          ),
        ],
      ),
    );
  }

  // Show urgent bookings
  void _showUrgentBookings() {
    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);
    final urgentBookings = _getUrgentBookings(bookingProvider.adminBookings);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.priority_high, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text(
                    'Urgent Bookings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${urgentBookings.length} items',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            // List
            Expanded(
              child: urgentBookings.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle,
                              size: 64, color: Colors.green),
                          SizedBox(height: 16),
                          Text(
                            'No urgent bookings!',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text('All bookings are being handled on time.'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: urgentBookings.length,
                      itemBuilder: (context, index) {
                        final booking = urgentBookings[index];
                        return _buildUrgentBookingCard(booking);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Show filtered bookings
  void _showFilteredBookings(String status) {
    setState(() {
      _selectedFilter =
          status.substring(0, 1).toUpperCase() + status.substring(1);
    });
    _tabController.animateTo(1);
  }

  // Show today's completed bookings
  void _showTodayCompletedBookings() {
    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);
    final todayCompleted = bookingProvider.adminBookings
        .where((booking) =>
            booking.status == AppConstants.completed &&
            booking.completedDate != null &&
            _isSameDay(booking.completedDate!, DateTime.now()))
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text(
                    'Today\'s Completed Services',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${todayCompleted.length} completed',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            // List
            Expanded(
              child: todayCompleted.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.schedule, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No services completed today yet',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: todayCompleted.length,
                      itemBuilder: (context, index) {
                        final booking = todayCompleted[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green,
                              child: const Icon(Icons.check_circle,
                                  color: Colors.white),
                            ),
                            title: Text(booking.serviceDisplayName),
                            subtitle: Text(
                              '${booking.customerName} • Completed: ${DateFormat('HH:mm').format(booking.completedDate!)}',
                            ),
                            trailing: Text(
                              '₹${booking.paymentAmount?.toInt() ?? 0}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            onTap: () => _showBookingDetails(booking),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Show sort options
  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Sort Bookings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Most Recent'),
              onTap: () {
                Navigator.pop(context);
                // Implement sorting logic
              },
            ),
            ListTile(
              leading: const Icon(Icons.priority_high),
              title: const Text('Most Urgent'),
              onTap: () {
                Navigator.pop(context);
                // Implement sorting logic
              },
            ),
            ListTile(
              leading: const Icon(Icons.monetization_on),
              title: const Text('Highest Value'),
              onTap: () {
                Navigator.pop(context);
                // Implement sorting logic
              },
            ),
          ],
        ),
      ),
    );
  }

  // Save admin notes
  void _saveAdminNotes(dynamic booking, String notes) async {
    if (notes.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter some notes before saving'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Saving notes...'),
          ],
        ),
      ),
    );

    final result =
        await bookingProvider.updateAdminNotes(booking.id, notes.trim());

    Navigator.pop(context); // Close loading dialog

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin notes saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save notes: ${result['message']}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Contact customer
  void _contactCustomer(dynamic booking) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Contact Customer',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.green),
              title: const Text('Call Customer'),
              subtitle: Text(booking.customerPhone),
              onTap: () {
                Navigator.pop(context);
                // Implement phone call
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Calling ${booking.customerPhone}...'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.message, color: Colors.blue),
              title: const Text('Send SMS'),
              subtitle: Text(booking.customerPhone),
              onTap: () {
                Navigator.pop(context);
                // Implement SMS
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('SMS feature coming soon'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // View location
  void _viewLocation(dynamic booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Customer Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Address:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(booking.customerAddress),
            const SizedBox(height: 16),
            const Text(
              'Map integration coming soon',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement map navigation
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Opening in maps...'),
                  backgroundColor: Colors.indigo,
                ),
              );
            },
            child: const Text('Open in Maps'),
          ),
        ],
      ),
    );
  }

  // Print booking details
  void _printBookingDetails(dynamic booking) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Print functionality coming soon'),
        backgroundColor: Colors.grey,
      ),
    );
  }

  // Multi-select mode methods
  void _enterMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = true;
      _selectedBookingIds.clear();
    });
  }

  void _enterMultiSelectModeWithSelection(String bookingId) {
    setState(() {
      _isMultiSelectMode = true;
      _selectedBookingIds.clear();
      _selectedBookingIds.add(bookingId);
    });
  }

  void _exitMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = false;
      _selectedBookingIds.clear();
    });
  }

  void _toggleBookingSelection(String bookingId) {
    setState(() {
      if (_selectedBookingIds.contains(bookingId)) {
        _selectedBookingIds.remove(bookingId);
      } else {
        _selectedBookingIds.add(bookingId);
      }
    });
  }

  // Bulk operations
  void _bulkAcceptSelected() {
    if (_selectedBookingIds.isEmpty) return;

    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);
    final selectedBookings = bookingProvider.adminBookings
        .where((booking) => _selectedBookingIds.contains(booking.id))
        .toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Accept Bookings'),
        content: Text('Accept ${selectedBookings.length} selected bookings?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performBulkAccept(selectedBookings);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Accept All'),
          ),
        ],
      ),
    );
  }

  void _bulkRejectSelected() {
    if (_selectedBookingIds.isEmpty) return;

    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);
    final selectedBookings = bookingProvider.adminBookings
        .where((booking) => _selectedBookingIds.contains(booking.id))
        .toList();

    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Reject Bookings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reject ${selectedBookings.length} selected bookings?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason',
                hintText: 'Enter reason for rejection...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a rejection reason'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(context);
              await _performBulkReject(
                  selectedBookings, reasonController.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject All'),
          ),
        ],
      ),
    );
  }

  Future<void> _performBulkAccept(List<dynamic> bookings) async {
    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Accepting bookings...'),
          ],
        ),
      ),
    );

    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);
    int successCount = 0;

    for (var booking in bookings) {
      final result = await bookingProvider.acceptBooking(booking.id);
      if (result['success']) successCount++;
    }

    Navigator.pop(context); // Close progress dialog
    _exitMultiSelectMode();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Successfully accepted $successCount of ${bookings.length} bookings'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _performBulkReject(List<dynamic> bookings, String reason) async {
    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Rejecting bookings...'),
          ],
        ),
      ),
    );

    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);
    int successCount = 0;

    for (var booking in bookings) {
      final result = await bookingProvider.rejectBooking(booking.id, reason);
      if (result['success']) successCount++;
    }

    Navigator.pop(context); // Close progress dialog
    _exitMultiSelectMode();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Successfully rejected $successCount of ${bookings.length} bookings'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // Communication history methods
  Widget _buildCommunicationHistory(dynamic booking) {
    // Build communication history from booking events
    final communicationEvents = <Map<String, dynamic>>[];

    // Add booking creation
    communicationEvents.add({
      'type': 'system',
      'message': 'Booking created by customer',
      'timestamp': booking.createdAt,
      'icon': Icons.add_circle,
      'color': Colors.blue,
    });

    // Add acceptance/rejection
    if (booking.acceptedDate != null) {
      communicationEvents.add({
        'type': 'admin',
        'message': 'Booking accepted by admin',
        'timestamp': booking.acceptedDate,
        'icon': Icons.check_circle,
        'color': Colors.green,
      });
    }

    if (booking.rejectedDate != null) {
      communicationEvents.add({
        'type': 'admin',
        'message':
            'Booking rejected: ${booking.rejectionReason ?? 'No reason provided'}',
        'timestamp': booking.rejectedDate,
        'icon': Icons.cancel,
        'color': Colors.red,
      });
    }

    // Add worker assignment
    if (booking.assignedDate != null) {
      communicationEvents.add({
        'type': 'admin',
        'message':
            'Worker assigned: ${booking.assignedEmployee?.name ?? 'Unknown'}',
        'timestamp': booking.assignedDate,
        'icon': Icons.person_add,
        'color': Colors.purple,
      });
    }

    // Add service completion
    if (booking.completedDate != null) {
      communicationEvents.add({
        'type': 'worker',
        'message': 'Service completed',
        'timestamp': booking.completedDate,
        'icon': Icons.check_circle_outline,
        'color': Colors.green,
      });
    }

    // Sort by timestamp
    communicationEvents.sort((a, b) =>
        (a['timestamp'] as DateTime).compareTo(b['timestamp'] as DateTime));

    if (communicationEvents.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'No communication history yet',
          style: TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: communicationEvents
          .map((event) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: event['color'],
                      child: Icon(
                        event['icon'],
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event['message'],
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('dd MMM yyyy, HH:mm')
                                .format(event['timestamp']),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: event['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        event['type'].toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: event['color'],
                        ),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  void _addCommunicationEntry(dynamic booking) {
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Communication Entry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Message',
                hintText: 'Enter communication message...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            const Text(
              'This will be added to the communication history for tracking purposes.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (messageController.text.trim().isNotEmpty) {
                Navigator.pop(context);
                _saveCommunicationEntry(booking, messageController.text.trim());
              }
            },
            child: const Text('Add Entry'),
          ),
        ],
      ),
    );
  }

  void _saveCommunicationEntry(dynamic booking, String message) {
    // For now, just show a success message
    // In a real implementation, you would save this to the backend
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Communication entry added: $message'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // Worker Assignment Dialog
  void _showWorkerAssignmentDialog(dynamic booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Worker'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Assign a worker to booking for ${booking.customerName}?'),
            const SizedBox(height: 16),
            const Text(
              'Worker assignment functionality will be available in the next update.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // For now, just mark as assigned with a placeholder worker
              final bookingProvider =
                  Provider.of<BookingProvider>(context, listen: false);
              
              // You can implement actual worker assignment logic here
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Worker assignment feature coming soon'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  // Worker Performance Dialog
  void _showWorkerPerformanceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Worker Performance'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.analytics, size: 48, color: Colors.blue),
            SizedBox(height: 16),
            Text('Worker Performance Dashboard'),
            SizedBox(height: 8),
            Text(
              'Detailed worker performance metrics and analytics will be available in the next update.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
