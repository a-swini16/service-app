import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/booking_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../models/booking_model.dart';

class ModernAdminPanelScreen extends StatefulWidget {
  const ModernAdminPanelScreen({Key? key}) : super(key: key);

  @override
  State<ModernAdminPanelScreen> createState() => _ModernAdminPanelScreenState();
}

class _ModernAdminPanelScreenState extends State<ModernAdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'all';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isLoggedIn) {
        throw Exception('Please login first');
      }

      final bookingProvider =
          Provider.of<BookingProvider>(context, listen: false);
      await bookingProvider.fetchAllBookings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ Loaded ${bookingProvider.adminBookings.length} bookings'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
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

  Map<String, int> _getStatusCounts(List<BookingModel> bookings) {
    final counts = <String, int>{
      'pending': 0,
      'accepted': 0,
      'assigned': 0,
      'in_progress': 0,
      'completed': 0,
      'rejected': 0,
    };

    for (final booking in bookings) {
      counts[booking.status] = (counts[booking.status] ?? 0) + 1;
    }

    return counts;
  }

  Map<String, int> _getPaymentCounts(List<BookingModel> bookings) {
    final counts = <String, int>{
      'paid': 0,
      'pending': 0,
      'failed': 0,
    };

    for (final booking in bookings) {
      counts[booking.paymentStatus] = (counts[booking.paymentStatus] ?? 0) + 1;
    }

    return counts;
  }

  double _getTotalRevenue(List<BookingModel> bookings) {
    return bookings
        .where((booking) =>
            booking.paymentStatus == 'paid' && booking.paymentAmount != null)
        .fold(0.0, (sum, booking) => sum + (booking.paymentAmount ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Admin Notifications
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      Navigator.pushNamed(context, '/user-notifications');
                    },
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
            onPressed: _isLoading ? null : _loadBookings,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.list_alt), text: 'Bookings'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
          ],
        ),
      ),
      body: Consumer<BookingProvider>(
        builder: (context, bookingProvider, child) {
          final allBookings = bookingProvider.adminBookings;
 
          return TabBarView( 
            controller: _tabController, 
            children: [ 
              _buildDashboardTab(allBookings), 
              _buildBookingsTab(), 
              _buildAnalyticsTab(allBookings), 
            ],
          );
        },
      ),
    );
  }

  Widget _buildDashboardTab(List<BookingModel> bookings) {
    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [Colors.indigo, Colors.indigo.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome to Admin Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage bookings, assign workers, and track progress',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Stats Cards
            const Text(
              'Overview',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _buildStatsGrid(bookings),

            const SizedBox(height: 20),

            // Recent Bookings
            const Text(
              'Recent Bookings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _buildRecentBookings(bookings),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(List<BookingModel> bookings) {
    final statusCounts = _getStatusCounts(bookings);
    final stats = [
      {
        'title': 'Total',
        'count': bookings.length,
        'color': Colors.blue,
        'icon': Icons.assignment
      },
      {
        'title': 'Pending',
        'count': statusCounts['pending']!,
        'color': Colors.orange,
        'icon': Icons.pending
      },
      {
        'title': 'Active',
        'count': (statusCounts['accepted']! +
            statusCounts['assigned']! +
            statusCounts['in_progress']!),
        'color': Colors.purple,
        'icon': Icons.work
      },
      {
        'title': 'Completed',
        'count': statusCounts['completed']!,
        'color': Colors.green,
        'icon': Icons.check_circle
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: (stat['color'] as Color).withOpacity(0.1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  stat['icon'] as IconData,
                  size: 32,
                  color: stat['color'] as Color,
                ),
                const SizedBox(height: 8),
                Text(
                  '${stat['count']}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: stat['color'] as Color,
                  ),
                ),
                Text(
                  stat['title'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentBookings(List<BookingModel> bookings) {
    final recentBookings = bookings.take(5).toList();

    if (recentBookings.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No bookings yet',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: recentBookings
          .map((booking) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(booking.status),
                    child: Icon(
                      _getStatusIcon(booking.status),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    booking.serviceType.replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                      '${booking.customerName} • ${booking.customerPhone}'),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(booking.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(booking.status).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      booking.status.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(booking.status),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  onTap: () {
                    _tabController.animateTo(1); // Switch to bookings tab
                  },
                ),
              ))
          .toList(),
    );
  }

  Widget _buildBookingsTab() {
    return Consumer<BookingProvider>(
        builder: (context, bookingProvider, child) {
      final allBookings = bookingProvider.adminBookings;
      final filteredBookings = _getFilteredBookings(allBookings);
      return Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                const Text(
                  'Filter: ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
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
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${filteredBookings.length} bookings',
                    style: TextStyle(
                      color: Colors.indigo,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
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
                        child: Scrollbar(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredBookings.length,
                            itemBuilder: (context, index) {
                              final booking = filteredBookings[index];
                              return _buildModernBookingCard(booking);
                            },
                          ),
                        ),
                      ),
          ),
        ],
      );
    });
  }

  Widget _buildModernBookingCard(BookingModel booking) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(booking.status).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getServiceIcon(booking.serviceType),
                  color: _getStatusColor(booking.status),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.serviceType.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(booking.status),
                        ),
                      ),
                      Text(
                        'ID: ${booking.id.substring(0, 8)}...',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    booking.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Customer Info
                Row(
                  children: [
                    Icon(Icons.person, color: Colors.grey[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        booking.customerName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.phone, color: Colors.grey[600], size: 20),
                    const SizedBox(width: 8),
                    Text(booking.customerPhone),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.grey[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        booking.customerAddress,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.schedule, color: Colors.grey[600], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${booking.preferredDate.day}/${booking.preferredDate.month}/${booking.preferredDate.year} at ${booking.preferredTime}',
                    ),
                  ],
                ),
                // Payment Information
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.payment, color: Colors.grey[600], size: 20),
                    const SizedBox(width: 8),
                    if (booking.paymentAmount != null) ...[
                      Text(
                        '₹${booking.paymentAmount}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getPaymentStatusColor(booking.paymentStatus)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getPaymentStatusColor(booking.paymentStatus)
                              .withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getPaymentStatusIcon(booking.paymentStatus),
                            size: 12,
                            color:
                                _getPaymentStatusColor(booking.paymentStatus),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Payment: ${booking.paymentStatus.toUpperCase()}',
                            style: TextStyle(
                              color:
                                  _getPaymentStatusColor(booking.paymentStatus),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Payment Method Information
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(_getPaymentMethodIcon(booking.paymentMethod),
                        color: Colors.grey[600], size: 20),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Text(
                        booking.paymentMethodDisplayName,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Action Buttons
                _buildActionButtons(booking),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BookingModel booking) {
    List<Widget> buttons = [];

    if (booking.status == 'pending') {
      buttons.addAll([
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _acceptBooking(booking),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Accept'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _rejectBooking(booking),
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Reject'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ]);
    } else if (booking.status == 'accepted') {
      buttons.add(
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _assignWorker(booking),
            icon: const Icon(Icons.person_add, size: 18),
            label: const Text('Assign Worker'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      );
    } else if (booking.status == 'assigned') {
      buttons.add(
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _startWork(booking),
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('Start Work'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      );
    } else if (booking.status == 'in_progress') {
      buttons.add(
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _completeWork(booking),
            icon: const Icon(Icons.check_circle, size: 18),
            label: const Text('Complete Work'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      );
    }

    return buttons.isEmpty ? const SizedBox.shrink() : Row(children: buttons);
  }

  Widget _buildAnalyticsTab(List<BookingModel> bookings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analytics Overview',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Service Type Distribution
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Service Distribution',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ..._getServiceDistribution(bookings)
                      .entries
                      .map(
                        (entry) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(entry.key
                                    .replaceAll('_', ' ')
                                    .toUpperCase()),
                              ),
                              Expanded(
                                flex: 2,
                                child: LinearProgressIndicator(
                                  value: bookings.isNotEmpty
                                      ? entry.value / bookings.length
                                      : 0,
                                  backgroundColor: Colors.grey[300],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.indigo),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('${entry.value}'),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Status Distribution
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status Distribution',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ..._getStatusCounts(bookings)
                      .entries
                      .where((e) => e.value > 0)
                      .map(
                        (entry) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _getStatusColor(entry.key),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(entry.key.toUpperCase()),
                              ),
                              Text(
                                '${entry.value}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ],
              ),
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
            color: Colors.grey[400],
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
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _selectedFilter == 'all'
                ? _loadBookings
                : () {
                    setState(() {
                      _selectedFilter = 'all';
                    });
                  },
            icon: Icon(_selectedFilter == 'all' ? Icons.refresh : Icons.clear),
            label: Text(_selectedFilter == 'all' ? 'Refresh' : 'Show All'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, int> _getServiceDistribution(List<BookingModel> bookings) {
    final distribution = <String, int>{};
    for (final booking in bookings) {
      distribution[booking.serviceType] =
          (distribution[booking.serviceType] ?? 0) + 1;
    }
    return distribution;
  }

  Map<String, int> _getPaymentMethodDistribution(List<BookingModel> bookings) {
    final distribution = <String, int>{};
    for (final booking in bookings) {
      distribution[booking.paymentMethod] =
          (distribution[booking.paymentMethod] ?? 0) + 1;
    }
    return distribution;
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
        return Colors.amber;
      case 'completed':
        return Colors.green;
      case 'rejected':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending;
      case 'accepted':
        return Icons.check;
      case 'assigned':
        return Icons.person;
      case 'in_progress':
        return Icons.work;
      case 'completed':
        return Icons.check_circle;
      case 'rejected':
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  IconData _getServiceIcon(String serviceType) {
    switch (serviceType) {
      case 'water_purifier':
        return Icons.water_drop;
      case 'ac_repair':
        return Icons.ac_unit;
      case 'refrigerator_repair':
        return Icons.kitchen;
      case 'dtdc_service':
        return Icons.local_shipping;
      default:
        return Icons.build;
    }
  }

  // Action Methods
  Future<void> _acceptBooking(BookingModel booking) async {
    try {
      final bookingProvider =
          Provider.of<BookingProvider>(context, listen: false);
      final result = await bookingProvider.acceptBooking(booking.id,
          adminNotes: 'Accepted by admin');

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Booking accepted successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadBookings();
      } else {
        throw Exception(result['message']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error accepting booking: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
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
            content: Text('✅ Booking rejected'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadBookings();
      } else {
        throw Exception(result['message']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error rejecting booking: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _assignWorker(BookingModel booking) async {
    try {
      final bookingProvider =
          Provider.of<BookingProvider>(context, listen: false);
      final workers = await bookingProvider.getAvailableWorkers(
          serviceType: booking.serviceType);

      if (workers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ No workers available for this service type'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final selectedWorkerId = await _showWorkerSelectionDialog(workers);

      if (selectedWorkerId != null) {
        final result =
            await bookingProvider.assignWorker(booking.id, selectedWorkerId);

        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Worker assigned successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _loadBookings();
        } else {
          throw Exception(result['message']);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error assigning worker: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: workers.length,
              itemBuilder: (context, index) {
                final worker = workers[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.indigo,
                      child: Text(
                        worker['name']?.substring(0, 1).toUpperCase() ?? 'W',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      worker['name'] ?? 'Unknown Worker',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('📞 ${worker['phone'] ?? 'N/A'}'),
                        if (worker['skills'] != null)
                          Text('🛠️ ${(worker['skills'] as List).join(', ')}'),
                      ],
                    ),
                    onTap: () {
                      Navigator.of(context).pop(worker['_id']);
                    },
                  ),
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
            content: Text('✅ Work started successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadBookings();
      } else {
        throw Exception(result['message']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error starting work: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
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
            content: Text('✅ Work completed successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadBookings();
      } else {
        throw Exception(result['message']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error completing work: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Color _getPaymentStatusColor(String paymentStatus) {
    switch (paymentStatus.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'refunded':
        return Colors.blue;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  IconData _getPaymentStatusIcon(String paymentStatus) {
    switch (paymentStatus.toLowerCase()) {
      case 'paid':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'failed':
        return Icons.error;
      case 'refunded':
        return Icons.undo;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.schedule;
    }
  }

  IconData _getPaymentMethodIcon(String paymentMethod) {
    switch (paymentMethod.toLowerCase()) {
      case 'cash_on_service':
        return Icons.money;
      case 'cash_on_hand':
        return Icons.account_balance_wallet;
      case 'online':
        return Icons.credit_card;
      case 'upi':
        return Icons.qr_code;
      case 'card':
        return Icons.credit_card;
      case 'wallet':
        return Icons.account_balance_wallet;
      default:
        return Icons.payment;
    }
  }
}
