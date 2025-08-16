import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../widgets/enhanced_admin_booking_widget.dart';

class EnhancedAdminPanelScreen extends StatefulWidget {
  const EnhancedAdminPanelScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedAdminPanelScreen> createState() => _EnhancedAdminPanelScreenState();
}

class _EnhancedAdminPanelScreenState extends State<EnhancedAdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _ensureAdminLogin();
    });
  }

  Future<void> _ensureAdminLogin() async {
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    
    // Skip authentication for now and directly fetch bookings
    debugPrint('📱 Fetching admin bookings...');
    try {
      await bookingProvider.fetchAllBookings();
      debugPrint('✅ Admin bookings fetched: ${bookingProvider.adminBookings.length}');
      
      // Debug: Show a snackbar with the count
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Loaded ${bookingProvider.adminBookings.length} bookings'),
            backgroundColor: bookingProvider.adminBookings.isEmpty ? Colors.orange : Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error fetching admin bookings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load bookings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
              await bookingProvider.fetchAllBookings();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data refreshed'),
                  backgroundColor: Colors.green,
                ),
              );
            },
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
            Tab(text: 'Bookings', icon: Icon(Icons.book_online)),
            Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const EnhancedAdminBookingWidget(),
          _buildAnalyticsTab(),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return Consumer<BookingProvider>(
      builder: (context, bookingProvider, child) {
        final bookings = bookingProvider.adminBookings;
        
        if (bookings.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.analytics, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No data available for analytics',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Calculate analytics
        final totalBookings = bookings.length;
        final completedBookings = bookings.where((b) => b.status == 'completed').length;
        final pendingBookings = bookings.where((b) => b.status == 'pending').length;
        final inProgressBookings = bookings.where((b) => b.status == 'in_progress').length;
        final rejectedBookings = bookings.where((b) => b.status == 'rejected').length;
        
        final completionRate = totalBookings > 0 ? (completedBookings / totalBookings * 100) : 0;
        final totalRevenue = bookings
            .where((b) => b.paymentAmount != null && b.isPaid)
            .fold(0.0, (sum, b) => sum + (b.actualAmount ?? b.paymentAmount ?? 0));

        return RefreshIndicator(
          onRefresh: () => bookingProvider.fetchAllBookings(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overview Cards
                const Text(
                  'Business Overview',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [
                    _buildAnalyticsCard(
                      'Total Bookings',
                      totalBookings.toString(),
                      Icons.book_online,
                      Colors.blue,
                    ),
                    _buildAnalyticsCard(
                      'Completion Rate',
                      '${completionRate.toStringAsFixed(1)}%',
                      Icons.check_circle,
                      Colors.green,
                    ),
                    _buildAnalyticsCard(
                      'Total Revenue',
                      '₹${totalRevenue.toStringAsFixed(0)}',
                      Icons.currency_rupee,
                      Colors.purple,
                    ),
                    _buildAnalyticsCard(
                      'Avg. per Booking',
                      completedBookings > 0 
                          ? '₹${(totalRevenue / completedBookings).toStringAsFixed(0)}'
                          : '₹0',
                      Icons.trending_up,
                      Colors.orange,
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Status Breakdown
                const Text(
                  'Status Breakdown',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                
                _buildStatusBreakdownCard(
                  'Pending', pendingBookings, Colors.orange, totalBookings,
                ),
                const SizedBox(height: 8),
                _buildStatusBreakdownCard(
                  'In Progress', inProgressBookings, Colors.indigo, totalBookings,
                ),
                const SizedBox(height: 8),
                _buildStatusBreakdownCard(
                  'Completed', completedBookings, Colors.green, totalBookings,
                ),
                const SizedBox(height: 8),
                _buildStatusBreakdownCard(
                  'Rejected', rejectedBookings, Colors.red, totalBookings,
                ),
                
                const SizedBox(height: 32),
                
                // Service Type Analysis
                const Text(
                  'Service Type Analysis',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                
                ..._buildServiceTypeAnalysis(bookings),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
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
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBreakdownCard(String status, int count, Color color, int total) {
    final percentage = total > 0 ? (count / total * 100) : 0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                status,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Text(
              '$count (${percentage.toStringAsFixed(1)}%)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildServiceTypeAnalysis(List bookings) {
    final serviceTypes = <String, int>{};
    for (final booking in bookings) {
      final serviceType = booking.serviceType;
      serviceTypes[serviceType] = (serviceTypes[serviceType] ?? 0) + 1;
    }

    return serviceTypes.entries.map((entry) {
      final serviceName = _getServiceDisplayName(entry.key);
      final count = entry.value;
      final percentage = bookings.isNotEmpty ? (count / bookings.length * 100) : 0;
      
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(_getServiceIcon(entry.key), color: Colors.deepPurple),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      serviceName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$count (${percentage.toStringAsFixed(1)}%)',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  String _getServiceDisplayName(String serviceType) {
    switch (serviceType) {
      case 'water_purifier':
        return 'Water Purifier Service';
      case 'ac_repair':
        return 'AC Repair Service';
      case 'refrigerator_repair':
        return 'Refrigerator Repair Service';
      default:
        return serviceType;
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
      default:
        return Icons.build;
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}