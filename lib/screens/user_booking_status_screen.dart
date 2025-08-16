import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../models/booking_model.dart';
import '../providers/booking_provider.dart';
import '../providers/auth_provider.dart';
import '../services/notification_service.dart';
import '../services/websocket_service.dart';

class UserBookingStatusScreen extends StatefulWidget {
  const UserBookingStatusScreen({Key? key}) : super(key: key);

  @override
  State<UserBookingStatusScreen> createState() =>
      _UserBookingStatusScreenState();
}

class _UserBookingStatusScreenState extends State<UserBookingStatusScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatusFilter = 'all';
  String _selectedSortOption = 'newest';
  String _selectedDateFilter = 'all';
  bool _showFilters = false;
  bool _showAdvancedFilters = false;
  late AnimationController _filterAnimationController;
  late Animation<double> _filterAnimation;
  Timer? _refreshTimer;
  Timer? _searchDebounceTimer;
  StreamSubscription? _notificationSubscription;
  StreamSubscription? _bookingStatusSubscription;
  StreamSubscription? _workerAssignmentSubscription;

  @override
  void initState() {
    super.initState();
    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _filterAnimation = CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.easeInOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // First ensure user is logged in with test credentials
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isLoggedIn) {
        print('🔐 User not logged in, attempting login...');
        final loginResult = await authProvider.login(
          email: 'testuser@example.com',
          password: 'password123',
        );
        if (loginResult['success'] != true) {
          print(
              '❌ Login failed in user booking status screen: ${loginResult['message']}');
          return;
        }
        print('✅ User logged in successfully');
      }

      final bookingProvider =
          Provider.of<BookingProvider>(context, listen: false);
      print('📱 Fetching user bookings...');
      await bookingProvider.fetchUserBookings();
      print('✅ User bookings fetched: ${bookingProvider.bookings.length}');

      _setupRealTimeUpdates();
      _setupWebSocketUpdates();
    });

    // Set up periodic refresh for real-time updates
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        final bookingProvider =
            Provider.of<BookingProvider>(context, listen: false);
        bookingProvider.fetchUserBookings();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _filterAnimationController.dispose();
    _refreshTimer?.cancel();
    _searchDebounceTimer?.cancel();
    _notificationSubscription?.cancel();
    _bookingStatusSubscription?.cancel();
    _workerAssignmentSubscription?.cancel();
    super.dispose();
  }

  void _setupRealTimeUpdates() {
    // Listen to notification stream for real-time updates
    _notificationSubscription =
        NotificationService.getNotificationStream().listen((notification) {
      if (notification.type.contains('booking') && mounted) {
        // Refresh bookings when booking-related notifications are received
        final bookingProvider =
            Provider.of<BookingProvider>(context, listen: false);
        bookingProvider.fetchUserBookings();

        // Show a snackbar for important updates
        if (notification.priority == 'high' ||
            notification.priority == 'urgent') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(notification.message),
              backgroundColor: _getNotificationColor(notification.type),
              action: SnackBarAction(
                label: 'View',
                onPressed: () {
                  final route =
                      NotificationService.getNavigationRoute(notification);
                  if (route != null && route != '/user-booking-status') {
                    Navigator.pushNamed(context, route);
                  }
                },
              ),
            ),
          );
        }
      }
    });

    // Subscribe to notifications for the current user
    // Note: Real-time notifications would be implemented with WebSocket connection
  }

  void _setupWebSocketUpdates() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final webSocketService = WebSocketService();

    print('🔌 Setting up WebSocket updates for user: ${authProvider.user?.id}');

    // Subscribe to user-specific booking updates
    if (authProvider.user?.id != null) {
      webSocketService.subscribeToUserBookingUpdates(authProvider.user!.id);

      // Listen for booking status updates
      _bookingStatusSubscription =
          webSocketService.bookingStatusUpdates.listen((update) {
        print(
            '📱 Received booking status update: ${update.bookingId} -> ${update.newStatus}');
        if (mounted) {
          final bookingProvider =
              Provider.of<BookingProvider>(context, listen: false);
          bookingProvider.fetchUserBookings();

          // Show notification to user
          if (update.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(update.message!),
                backgroundColor: _getStatusColor(update.newStatus),
                action: SnackBarAction(
                  label: 'View',
                  onPressed: () {
                    // Scroll to the updated booking or show details
                  },
                ),
              ),
            );
          }
        }
      });

      // Listen for worker assignments
      _workerAssignmentSubscription =
          webSocketService.workerAssignments.listen((assignment) {
        if (mounted) {
          final bookingProvider =
              Provider.of<BookingProvider>(context, listen: false);
          bookingProvider.fetchUserBookings();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Worker ${assignment.worker.name} has been assigned to your booking'),
              backgroundColor: Colors.purple,
              action: SnackBarAction(
                label: 'View',
                onPressed: () {
                  // Show booking details
                },
              ),
            ),
          );
        }
      });
    }
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
      default:
        return Colors.grey;
    }
  }

  Future<void> _handleRefresh() async {
    try {
      final bookingProvider =
          Provider.of<BookingProvider>(context, listen: false);
      await bookingProvider.fetchUserBookings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bookings updated'),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to refresh bookings'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'booking_accepted':
        return Colors.green;
      case 'booking_rejected':
        return Colors.red;
      case 'worker_assigned':
        return Colors.purple;
      case 'service_completed':
        return Colors.blue;
      case 'payment_required':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  List<BookingModel> _getFilteredBookings(List<BookingModel> bookings) {
    List<BookingModel> filtered = bookings;

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      filtered = filtered.where((booking) {
        return booking.serviceDisplayName.toLowerCase().contains(searchTerm) ||
            booking.customerName.toLowerCase().contains(searchTerm) ||
            booking.statusDisplayName.toLowerCase().contains(searchTerm) ||
            booking.id.toLowerCase().contains(searchTerm) ||
            booking.customerAddress.toLowerCase().contains(searchTerm) ||
            (booking.assignedEmployeeName?.toLowerCase().contains(searchTerm) ??
                false) ||
            (booking.description?.toLowerCase().contains(searchTerm) ?? false);
      }).toList();
    }

    // Apply status filter
    if (_selectedStatusFilter != 'all') {
      if (_selectedStatusFilter == 'active') {
        filtered = filtered
            .where((booking) => ['accepted', 'assigned', 'in_progress']
                .contains(booking.status))
            .toList();
      } else if (_selectedStatusFilter == 'needs_payment') {
        filtered = filtered
            .where(
                (booking) => booking.status == 'completed' && !booking.isPaid)
            .toList();
      } else {
        filtered = filtered
            .where((booking) => booking.status == _selectedStatusFilter)
            .toList();
      }
    }

    // Apply date filter
    if (_selectedDateFilter != 'all') {
      final now = DateTime.now();
      switch (_selectedDateFilter) {
        case 'today':
          filtered = filtered
              .where((booking) =>
                  booking.createdAt.day == now.day &&
                  booking.createdAt.month == now.month &&
                  booking.createdAt.year == now.year)
              .toList();
          break;
        case 'this_week':
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          filtered = filtered
              .where((booking) => booking.createdAt.isAfter(weekStart))
              .toList();
          break;
        case 'this_month':
          filtered = filtered
              .where((booking) =>
                  booking.createdAt.month == now.month &&
                  booking.createdAt.year == now.year)
              .toList();
          break;
        case 'last_30_days':
          final thirtyDaysAgo = now.subtract(const Duration(days: 30));
          filtered = filtered
              .where((booking) => booking.createdAt.isAfter(thirtyDaysAgo))
              .toList();
          break;
      }
    }

    // Apply sorting
    switch (_selectedSortOption) {
      case 'newest':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'oldest':
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'date_asc':
        filtered.sort((a, b) => a.preferredDate.compareTo(b.preferredDate));
        break;
      case 'date_desc':
        filtered.sort((a, b) => b.preferredDate.compareTo(a.preferredDate));
        break;
      case 'amount_high':
        filtered.sort(
            (a, b) => (b.paymentAmount ?? 0).compareTo(a.paymentAmount ?? 0));
        break;
      case 'amount_low':
        filtered.sort(
            (a, b) => (a.paymentAmount ?? 0).compareTo(b.paymentAmount ?? 0));
        break;
      case 'progress':
        filtered.sort((a, b) =>
            _getProgressPercentage(b).compareTo(_getProgressPercentage(a)));
        break;
      case 'status':
        filtered.sort((a, b) => a.status.compareTo(b.status));
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon:
                Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
                if (_showFilters) {
                  _filterAnimationController.forward();
                } else {
                  _filterAnimationController.reverse();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.timeline),
            onPressed: () {
              final bookingProvider =
                  Provider.of<BookingProvider>(context, listen: false);
              final filteredBookings =
                  _getFilteredBookings(bookingProvider.bookings);
              _showTimelineView(filteredBookings);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final bookingProvider =
                  Provider.of<BookingProvider>(context, listen: false);
              bookingProvider.fetchUserBookings();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/booking-form');
        },
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Consumer<BookingProvider>(
        builder: (context, bookingProvider, child) {
          if (bookingProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final allBookings = bookingProvider.bookings;
          final filteredBookings = _getFilteredBookings(allBookings);

          return Column(
            children: [
              // Search and Filter Section
              AnimatedBuilder(
                animation: _filterAnimation,
                builder: (context, child) {
                  return SizeTransition(
                    sizeFactor: _filterAnimation,
                    child: _buildSearchAndFilterSection(),
                  );
                },
              ),

              // Bookings Summary
              if (allBookings.isNotEmpty) _buildBookingsSummary(allBookings),

              // Bookings List
              Expanded(
                child: filteredBookings.isEmpty
                    ? _buildEmptyState(allBookings.isEmpty)
                    : RefreshIndicator(
                        onRefresh: () => _handleRefresh(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredBookings.length,
                          itemBuilder: (context, index) {
                            final booking = filteredBookings[index];
                            return _buildEnhancedBookingCard(booking);
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchAndFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by service, name, status, or booking ID...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              _searchDebounceTimer?.cancel();
              _searchDebounceTimer =
                  Timer(const Duration(milliseconds: 500), () {
                if (mounted) {
                  setState(() {});
                }
              });
            },
          ),
          const SizedBox(height: 16),

          // Filter Row
          Row(
            children: [
              // Status Filter
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedStatusFilter,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Status')),
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(
                        value: 'accepted', child: Text('Accepted')),
                    DropdownMenuItem(
                        value: 'assigned', child: Text('Assigned')),
                    DropdownMenuItem(
                        value: 'in_progress', child: Text('In Progress')),
                    DropdownMenuItem(
                        value: 'completed', child: Text('Completed')),
                    DropdownMenuItem(
                        value: 'rejected', child: Text('Rejected')),
                    DropdownMenuItem(
                        value: 'active', child: Text('Active Bookings')),
                    DropdownMenuItem(
                        value: 'needs_payment', child: Text('Needs Payment')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedStatusFilter = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),

              // Sort Filter
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedSortOption,
                  decoration: InputDecoration(
                    labelText: 'Sort By',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'newest', child: Text('Newest First')),
                    DropdownMenuItem(
                        value: 'oldest', child: Text('Oldest First')),
                    DropdownMenuItem(
                        value: 'date_asc', child: Text('Date (Earliest)')),
                    DropdownMenuItem(
                        value: 'date_desc', child: Text('Date (Latest)')),
                    DropdownMenuItem(
                        value: 'amount_high', child: Text('Amount (High)')),
                    DropdownMenuItem(
                        value: 'amount_low', child: Text('Amount (Low)')),
                    DropdownMenuItem(
                        value: 'progress', child: Text('Progress')),
                    DropdownMenuItem(value: 'status', child: Text('Status')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedSortOption = value!;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Advanced Filters Toggle
          Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showAdvancedFilters = !_showAdvancedFilters;
                  });
                },
                icon: Icon(_showAdvancedFilters
                    ? Icons.expand_less
                    : Icons.expand_more),
                label: Text(_showAdvancedFilters
                    ? 'Hide Advanced Filters'
                    : 'Show Advanced Filters'),
              ),
              const Spacer(),
              if (_selectedStatusFilter != 'all' ||
                  _selectedDateFilter != 'all' ||
                  _searchController.text.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _selectedStatusFilter = 'all';
                      _selectedDateFilter = 'all';
                      _selectedSortOption = 'newest';
                    });
                  },
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear All'),
                ),
            ],
          ),

          // Advanced Filters
          if (_showAdvancedFilters) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                // Date Filter
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedDateFilter,
                    decoration: InputDecoration(
                      labelText: 'Date Range',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Time')),
                      DropdownMenuItem(value: 'today', child: Text('Today')),
                      DropdownMenuItem(
                          value: 'this_week', child: Text('This Week')),
                      DropdownMenuItem(
                          value: 'this_month', child: Text('This Month')),
                      DropdownMenuItem(
                          value: 'last_30_days', child: Text('Last 30 Days')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedDateFilter = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBookingsSummary(List<BookingModel> bookings) {
    final statusCounts = <String, int>{};
    for (final booking in bookings) {
      statusCounts[booking.status] = (statusCounts[booking.status] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Total',
              bookings.length.toString(),
              Colors.blue,
              Icons.book_online,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSummaryCard(
              'Pending',
              (statusCounts['pending'] ?? 0).toString(),
              Colors.orange,
              Icons.pending,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSummaryCard(
              'Active',
              ((statusCounts['accepted'] ?? 0) +
                      (statusCounts['assigned'] ?? 0) +
                      (statusCounts['in_progress'] ?? 0))
                  .toString(),
              Colors.purple,
              Icons.work,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSummaryCard(
              'Completed',
              (statusCounts['completed'] ?? 0).toString(),
              Colors.green,
              Icons.check_circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
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

  Widget _buildEmptyState(bool isCompletelyEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isCompletelyEmpty ? Icons.book_online : Icons.search_off,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            isCompletelyEmpty
                ? 'No bookings found'
                : 'No bookings match your filters',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            isCompletelyEmpty
                ? 'Create a new booking to get started'
                : 'Try adjusting your search or filters',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          if (isCompletelyEmpty) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/booking-form');
              },
              icon: const Icon(Icons.add),
              label: const Text('Create New Booking'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
          if (!isCompletelyEmpty) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _selectedStatusFilter = 'all';
                  _selectedSortOption = 'newest';
                });
              },
              child: const Text('Clear Filters'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEnhancedBookingCard(BookingModel booking) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () => _showBookingDetails(booking),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with service name and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.serviceDisplayName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(booking.status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      booking.statusDisplayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Progress Bar
              _buildProgressBar(booking),
              const SizedBox(height: 12),

              // Next Action and Estimated Time
              _buildNextActionInfo(booking),
              const SizedBox(height: 12),

              // Status Timeline (Compact)
              _buildCompactStatusTimeline(booking),
              const SizedBox(height: 12),

              // Booking Details
              _buildBookingDetails(booking),
              const SizedBox(height: 12),

              // Action Buttons
              _buildActionButtons(booking),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(BookingModel booking) {
    final progressPercentage = _getProgressPercentage(booking);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            Text(
              '${(progressPercentage * 100).toInt()}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _getStatusColor(booking.status),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progressPercentage,
          backgroundColor: Colors.grey[300],
          valueColor:
              AlwaysStoppedAnimation<Color>(_getStatusColor(booking.status)),
        ),
      ],
    );
  }

  double _getProgressPercentage(BookingModel booking) {
    switch (booking.status) {
      case 'pending':
        return 0.2;
      case 'accepted':
        return 0.4;
      case 'assigned':
        return 0.6;
      case 'in_progress':
        return 0.8;
      case 'completed':
        return booking.isPaid ? 1.0 : 0.9;
      case 'rejected':
      case 'cancelled':
        return 0.0;
      default:
        return 0.0;
    }
  }

  Widget _buildNextActionInfo(BookingModel booking) {
    final nextAction = _getNextExpectedAction(booking);
    final estimatedTime = _getEstimatedCompletionTime(booking);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.blue[600],
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nextAction,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue[800],
                  ),
                ),
                if (estimatedTime != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Est. completion: ${DateFormat('MMM dd, HH:mm').format(estimatedTime)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getNextExpectedAction(BookingModel booking) {
    switch (booking.status) {
      case 'pending':
        return 'Waiting for admin review';
      case 'accepted':
        return 'Waiting for worker assignment';
      case 'assigned':
        return 'Worker will arrive on scheduled date';
      case 'in_progress':
        return 'Service in progress';
      case 'completed':
        return booking.isPaid
            ? 'Service completed and paid'
            : 'Payment pending';
      case 'rejected':
        return 'Booking was rejected';
      case 'cancelled':
        return 'Booking was cancelled';
      default:
        return 'Unknown status';
    }
  }

  DateTime? _getEstimatedCompletionTime(BookingModel booking) {
    switch (booking.status) {
      case 'pending':
        return booking.createdAt
            .add(const Duration(hours: 24)); // 24 hours for admin review
      case 'accepted':
        return booking.createdAt
            .add(const Duration(hours: 48)); // 48 hours for worker assignment
      case 'assigned':
        return booking.preferredDate
            .add(const Duration(hours: 2)); // 2 hours after preferred time
      case 'in_progress':
        return booking.startedDate
            ?.add(const Duration(hours: 4)); // 4 hours for completion
      default:
        return null;
    }
  }

  Widget _buildCompactStatusTimeline(BookingModel booking) {
    final statuses = [
      {'status': 'pending', 'icon': Icons.create, 'label': 'Created'},
      {'status': 'accepted', 'icon': Icons.check_circle, 'label': 'Accepted'},
      {'status': 'assigned', 'icon': Icons.person, 'label': 'Assigned'},
      {'status': 'in_progress', 'icon': Icons.build, 'label': 'In Progress'},
      {'status': 'completed', 'icon': Icons.done_all, 'label': 'Completed'},
    ];

    return Row(
      children: statuses.asMap().entries.map((entry) {
        final index = entry.key;
        final statusInfo = entry.value;
        final isCompleted =
            _isStatusCompleted(booking, statusInfo['status'] as String);
        final isCurrent = booking.status == statusInfo['status'];
        final color = isCompleted || isCurrent
            ? _getStatusColor(booking.status)
            : Colors.grey[400]!;

        return Expanded(
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  statusInfo['icon'] as IconData,
                  color: Colors.white,
                  size: 12,
                ),
              ),
              if (index < statuses.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    color: isCompleted ? color : Colors.grey[300],
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons(BookingModel booking) {
    List<Widget> buttons = [];

    if (booking.status == 'completed' && !booking.isPaid) {
      buttons.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showPaymentDialog(booking),
            icon: const Icon(Icons.payment),
            label: const Text('Pay Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      );
    }

    buttons.add(
      Expanded(
        child: OutlinedButton.icon(
          onPressed: () => _showDetailedTimeline(booking),
          icon: const Icon(Icons.timeline),
          label: const Text('View Timeline'),
        ),
      ),
    );

    if (buttons.length == 1) {
      return buttons.first;
    } else if (buttons.length > 1) {
      return Row(
        children: buttons
            .expand((button) => [button, const SizedBox(width: 8)])
            .take(buttons.length * 2 - 1)
            .toList(),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildBookingDetails(BookingModel booking) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Date: ${DateFormat('dd MMM yyyy').format(booking.preferredDate)}',
              style: TextStyle(color: Colors.grey[700]),
            ),
            Text(
              'Time: ${booking.preferredTime}',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Amount: ₹${booking.paymentAmount?.toInt() ?? 0}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green[600],
            fontSize: 16,
          ),
        ),
        if (booking.assignedEmployeeName != null) ...[
          const SizedBox(height: 4),
          Text(
            'Worker: ${booking.assignedEmployeeName}',
            style: TextStyle(color: Colors.grey[700]),
          ),
        ],
        if (booking.actualAmount != null) ...[
          const SizedBox(height: 4),
          Text(
            'Final Amount: ₹${booking.actualAmount!.toInt()}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue[600],
            ),
          ),
        ],
      ],
    );
  }

  void _showBookingDetails(BookingModel booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(booking.serviceDisplayName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Status', booking.statusDisplayName),
              _buildDetailRow('Customer', booking.customerName),
              _buildDetailRow('Phone', booking.customerPhone),
              _buildDetailRow('Address', booking.customerAddress),
              _buildDetailRow('Date',
                  DateFormat('dd MMM yyyy').format(booking.preferredDate)),
              _buildDetailRow('Time', booking.preferredTime),
              if (booking.description?.isNotEmpty == true)
                _buildDetailRow('Description', booking.description!),
              _buildDetailRow(
                  'Amount', '₹${booking.paymentAmount?.toInt() ?? 0}'),
              _buildDetailRow(
                  'Payment Method', booking.paymentMethodDisplayName),
              if (booking.assignedEmployeeName != null)
                _buildDetailRow(
                    'Assigned Worker', booking.assignedEmployeeName!),
              if (booking.actualAmount != null)
                _buildDetailRow(
                    'Final Amount', '₹${booking.actualAmount!.toInt()}'),
              if (booking.adminNotes?.isNotEmpty == true)
                _buildDetailRow('Admin Notes', booking.adminNotes!),
              if (booking.workerNotes?.isNotEmpty == true)
                _buildDetailRow('Worker Notes', booking.workerNotes!),
              if (booking.rejectionReason?.isNotEmpty == true)
                _buildDetailRow('Rejection Reason', booking.rejectionReason!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (booking.status == 'completed' && !booking.isPaid)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showPaymentDialog(booking);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              child: const Text('Process Payment',
                  style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  void _showPaymentDialog(BookingModel booking) {
    // Navigate to the dedicated payment screen instead of showing a dialog
    Navigator.pushNamed(
      context,
      '/payment',
      arguments: {
        'booking': booking,
        'isPostService': true,
      },
    ).then((_) {
      // Refresh bookings when returning from payment screen
      final bookingProvider =
          Provider.of<BookingProvider>(context, listen: false);
      bookingProvider.fetchUserBookings();
    });
  }

  Future<void> _processPayment(
      BookingModel booking, double amount, String paymentMethod) async {
    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);
    final result = await bookingProvider.completePayment(
      booking.id,
      amount,
      paymentMethod,
    );

    if (!mounted) return;

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment processed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      // Refresh bookings
      await bookingProvider.fetchUserBookings();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to process payment'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text('$label:',
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  bool _isStatusCompleted(BookingModel booking, String status) {
    const statusOrder = [
      'pending',
      'accepted',
      'assigned',
      'in_progress',
      'completed',
      'paid'
    ];

    final currentIndex = statusOrder.indexOf(booking.status);
    final checkIndex = statusOrder.indexOf(status);

    if (status == 'paid') {
      return booking.isPaid;
    }

    return checkIndex <= currentIndex;
  }

  void _showTimelineView(List<BookingModel> bookings) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Booking Timeline View',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    return _buildTimelineCard(booking);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineCard(BookingModel booking) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  booking.serviceDisplayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailedTimeline(booking),
          ],
        ),
      ),
    );
  }

  void _showDetailedTimeline(BookingModel booking) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Booking Timeline',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.serviceDisplayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Booking ID: ${booking.id}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildDetailedTimeline(booking),
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

  Widget _buildDetailedTimeline(BookingModel booking) {
    List<Map<String, dynamic>> timelineEvents = [];

    // Add events based on booking data
    timelineEvents.add({
      'title': 'Booking Created',
      'subtitle': 'Service request submitted',
      'time': booking.createdAt,
      'icon': Icons.create,
      'color': Colors.blue,
      'isCompleted': true,
    });

    if (booking.acceptedDate != null) {
      timelineEvents.add({
        'title': 'Booking Accepted',
        'subtitle': 'Admin approved the service request',
        'time': booking.acceptedDate!,
        'icon': Icons.check_circle,
        'color': Colors.green,
        'isCompleted': true,
      });
    }

    if (booking.assignedDate != null && booking.assignedEmployeeName != null) {
      timelineEvents.add({
        'title': 'Worker Assigned',
        'subtitle': 'Worker: ${booking.assignedEmployeeName}',
        'time': booking.assignedDate!,
        'icon': Icons.person,
        'color': Colors.purple,
        'isCompleted': true,
      });
    }

    if (booking.startedDate != null) {
      timelineEvents.add({
        'title': 'Service Started',
        'subtitle': 'Worker began the service',
        'time': booking.startedDate!,
        'icon': Icons.build,
        'color': Colors.orange,
        'isCompleted': true,
      });
    }

    if (booking.completedDate != null) {
      timelineEvents.add({
        'title': 'Service Completed',
        'subtitle': 'Work finished successfully',
        'time': booking.completedDate!,
        'icon': Icons.done_all,
        'color': Colors.green,
        'isCompleted': true,
      });
    }

    if (booking.isPaid) {
      timelineEvents.add({
        'title': 'Payment Completed',
        'subtitle':
            'Amount: ₹${booking.actualAmount?.toInt() ?? booking.paymentAmount?.toInt() ?? 0}',
        'time': booking.completedDate ?? DateTime.now(), // Approximate time
        'icon': Icons.payment,
        'color': Colors.green,
        'isCompleted': true,
      });
    }

    if (booking.rejectedDate != null) {
      timelineEvents.add({
        'title': 'Booking Rejected',
        'subtitle': booking.rejectionReason ?? 'No reason provided',
        'time': booking.rejectedDate!,
        'icon': Icons.cancel,
        'color': Colors.red,
        'isCompleted': true,
      });
    }

    // Add status history if available (placeholder for now)
    // TODO: Implement status history when backend provides it

    // Sort by time
    timelineEvents.sort(
        (a, b) => (a['time'] as DateTime).compareTo(b['time'] as DateTime));

    return Column(
      children: timelineEvents.asMap().entries.map((entry) {
        final index = entry.key;
        final event = entry.value;
        final isLast = index == timelineEvents.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: event['color'],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    event['icon'],
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 60,
                    color: Colors.grey[300],
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event['title'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event['subtitle'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM dd, yyyy HH:mm').format(event['time']),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
