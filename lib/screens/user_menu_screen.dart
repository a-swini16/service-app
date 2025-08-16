import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';

class UserMenuScreen extends StatefulWidget {
  @override
  _UserMenuScreenState createState() => _UserMenuScreenState();
}

class _UserMenuScreenState extends State<UserMenuScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bookingProvider =
          Provider.of<BookingProvider>(context, listen: false);
      bookingProvider.fetchUserBookings();
    });
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
        title: Text('My Account'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Profile', icon: Icon(Icons.person)),
            Tab(text: 'Bookings', icon: Icon(Icons.book_online)),
            Tab(text: 'Settings', icon: Icon(Icons.settings)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProfileTab(),
          _buildBookingsTab(),
          _buildSettingsTab(),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;

        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Profile Header
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple[100]!, Colors.blue[50]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.deepPurple,
                      child: Text(
                        user?.name.substring(0, 1).toUpperCase() ?? 'U',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      user?.name ?? 'User',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      user?.email ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Profile Information
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Personal Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      _buildInfoRow(Icons.person, 'Name', user?.name ?? 'N/A'),
                      _buildInfoRow(Icons.email, 'Email', user?.email ?? 'N/A'),
                      _buildInfoRow(Icons.phone, 'Phone', user?.phone ?? 'N/A'),
                      _buildInfoRow(
                          Icons.location_on, 'Address', user?.address ?? 'N/A'),
                      SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // TODO: Implement edit profile
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Edit profile feature coming soon!')),
                            );
                          },
                          icon: Icon(Icons.edit),
                          label: Text('Edit Profile'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBookingsTab() {
    return Consumer<BookingProvider>(
      builder: (context, bookingProvider, child) {
        if (bookingProvider.isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        final bookings = bookingProvider.bookings;

        if (bookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.book_online,
                  size: 64,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  'No bookings yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Book your first service to get started',
                  style: TextStyle(
                    color: Colors.grey[500],
                  ),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/home');
                  },
                  child: Text('Book Service'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Bookings (${bookings.length})',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/user-booking-status');
                    },
                    child: Text('View All'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: bookings.length > 3 ? 3 : bookings.length,
                itemBuilder: (context, index) {
                  final booking = bookings[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getStatusColor(booking.status),
                        child: Icon(
                          _getStatusIcon(booking.status),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(booking.serviceDisplayName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${DateFormat('dd MMM yyyy').format(booking.preferredDate)} at ${booking.preferredTime}',
                          ),
                          Text(
                            booking.statusDisplayName,
                            style: TextStyle(
                              color: _getStatusColor(booking.status),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      trailing: Text(
                        '₹${booking.actualAmount?.toInt() ?? booking.paymentAmount?.toInt() ?? 0}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[600],
                        ),
                      ),
                      onTap: () {
                        Navigator.pushNamed(context, '/user-booking-status');
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );

        return RefreshIndicator(
          onRefresh: () => bookingProvider.fetchUserBookings(),
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return Card(
                margin: EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              booking.serviceDisplayName,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(booking.status),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              booking.status.toUpperCase(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      _buildBookingInfoRow(Icons.person, booking.customerName),
                      _buildBookingInfoRow(Icons.phone, booking.customerPhone),
                      _buildBookingInfoRow(
                          Icons.calendar_today,
                          DateFormat('dd MMM yyyy')
                              .format(booking.preferredDate)),
                      _buildBookingInfoRow(
                          Icons.access_time, booking.preferredTime),
                      if (booking.description?.isNotEmpty == true)
                        _buildBookingInfoRow(
                            Icons.description, booking.description!),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Amount: ₹${booking.paymentAmount?.toInt() ?? 0}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[600],
                            ),
                          ),
                          if (booking.status == 'pending')
                            TextButton(
                              onPressed: () {
                                _showCancelBookingDialog(booking.id);
                              },
                              child: Text(
                                'Cancel',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Column(
              children: [
                _buildSettingsTile(
                  Icons.security,
                  'Privacy & Security',
                  'Manage your privacy settings',
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Privacy settings coming soon!')),
                    );
                  },
                ),
                Divider(height: 1),
                _buildSettingsTile(
                  Icons.help,
                  'Help & Support',
                  'Get help and contact support',
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Help & Support coming soon!')),
                    );
                  },
                ),
                Divider(height: 1),
                _buildSettingsTile(
                  Icons.info,
                  'About',
                  'App version and information',
                  () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'Om Enterprises',
                      applicationVersion: '1.0.0',
                      applicationLegalese:
                          '© 2024 Om Enterprises. All rights reserved.',
                    );
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          Card(
            child: _buildSettingsTile(
              Icons.logout,
              'Logout',
              'Sign out of your account',
              () {
                _showLogoutDialog();
              },
              textColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingInfoRow(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? Colors.grey[600]),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
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
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'accepted':
        return Icons.check_circle;
      case 'assigned':
        return Icons.person;
      case 'in_progress':
        return Icons.build;
      case 'completed':
        return Icons.done_all;
      case 'rejected':
        return Icons.cancel;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  void _showCancelBookingDialog(String bookingId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Booking'),
        content: Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement cancel booking
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Cancel booking feature coming soon!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }
}
