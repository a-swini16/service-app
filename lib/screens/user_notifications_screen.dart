import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/notification_model.dart';
import '../providers/notification_provider.dart';
import '../providers/auth_provider.dart';
import '../services/notification_service.dart';

class UserNotificationsScreen extends StatefulWidget {
  const UserNotificationsScreen({Key? key}) : super(key: key);

  @override
  State<UserNotificationsScreen> createState() =>
      _UserNotificationsScreenState();
}

class _UserNotificationsScreenState extends State<UserNotificationsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final notificationProvider =
          Provider.of<NotificationProvider>(context, listen: false);

      if (authProvider.user != null) {
        notificationProvider.fetchUserNotifications(
          authProvider.user!.id,
          refresh: true,
        );
      }
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreNotifications();
    }
  }

  Future<void> _loadMoreNotifications() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);

    if (authProvider.user != null) {
      await notificationProvider.fetchUserNotifications(authProvider.user!.id);
    }

    setState(() {
      _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              if (notificationProvider.unreadCount > 0) {
                return IconButton(
                  icon: const Icon(Icons.mark_email_read),
                  onPressed: () => _markAllAsRead(),
                  tooltip: 'Mark all as read',
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshNotifications(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer2<NotificationProvider, AuthProvider>(
        builder: (context, notificationProvider, authProvider, child) {
          if (notificationProvider.isLoading &&
              notificationProvider.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (notificationProvider.notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No notifications',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'You\'ll see notifications about your bookings here',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => _refreshNotifications(),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: notificationProvider.notifications.length +
                  (_isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == notificationProvider.notifications.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final notification = notificationProvider.notifications[index];
                return _buildNotificationCard(
                    notification, notificationProvider);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification,
      NotificationProvider notificationProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _onNotificationTap(notification),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: notification.isRead
                  ? Colors.transparent
                  : Colors.blue.withOpacity(0.3),
              width: notification.isRead ? 0 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: notification.priorityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        notification.typeIcon,
                        color: notification.priorityColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                              color: notification.isRead
                                  ? Colors.grey[700]
                                  : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notification.message,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (!notification.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('dd MMM yyyy, hh:mm a')
                          .format(notification.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: notification.priorityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        notification.priorityDisplayName,
                        style: TextStyle(
                          fontSize: 10,
                          color: notification.priorityColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                if (notification.relatedBookingId != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.book_online,
                          size: 14,
                          color: Colors.green[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Booking Related',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onNotificationTap(NotificationModel notification) async {
    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);

    // Mark as read if not already read
    if (!notification.isRead) {
      await notificationProvider.markAsRead(notification.id);
    }

    // Handle payment required notifications specially
    if (notification.type == 'payment_required' && 
        notification.data != null && 
        notification.relatedBookingId != null) {
      
      final amount = (notification.data!['actualAmount'] ?? 
                     notification.data!['paymentAmount'] ?? 0).toDouble();
      final serviceType = notification.data!['serviceType'] ?? 'Service';
      
      if (amount > 0) {
        // Navigate directly to payment screen
        Navigator.pushNamed(
          context,
          '/payment',
          arguments: {
            'bookingId': notification.relatedBookingId!,
            'amount': amount,
            'serviceType': serviceType,
            'isPostService': true,
            'autoNavigated': true,
          },
        );
        return;
      }
    }

    // Show notification details for other types
    _showNotificationDetails(notification);
  }

  void _showNotificationDetails(NotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              notification.typeIcon,
              color: notification.priorityColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                notification.title,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                notification.message,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Type', notification.typeDisplayName),
              _buildDetailRow('Priority', notification.priorityDisplayName),
              _buildDetailRow(
                  'Date',
                  DateFormat('dd MMM yyyy, hh:mm a')
                      .format(notification.createdAt)),
              if (notification.relatedBookingId != null)
                _buildDetailRow('Booking ID', notification.relatedBookingId!),
              if (notification.isRead && notification.readAt != null)
                _buildDetailRow(
                    'Read At',
                    DateFormat('dd MMM yyyy, hh:mm a')
                        .format(notification.readAt!)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (notification.type == 'payment_required' && 
              notification.data != null && 
              notification.relatedBookingId != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToPayment(notification);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Pay Now',
                  style: TextStyle(color: Colors.white)),
            )
          else if (notification.relatedBookingId != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToBooking(notification.relatedBookingId!);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('View Booking',
                  style: TextStyle(color: Colors.white)),
            ),
        ],
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
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToBooking(String bookingId) {
    // Navigate to booking details or booking status screen
    // This would depend on your app's navigation structure
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigate to booking: $bookingId'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _navigateToPayment(NotificationModel notification) {
    final amount = (notification.data!['actualAmount'] ?? 
                   notification.data!['paymentAmount'] ?? 0).toDouble();
    final serviceType = notification.data!['serviceType'] ?? 'Service';
    
    Navigator.pushNamed(
      context,
      '/payment',
      arguments: {
        'bookingId': notification.relatedBookingId!,
        'amount': amount,
        'serviceType': serviceType,
        'isPostService': true,
        'autoNavigated': true,
      },
    );
  }

  Future<void> _markAllAsRead() async {
    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);
    await notificationProvider.markAllAsRead();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _refreshNotifications() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);

    if (authProvider.user != null) {
      await notificationProvider.fetchUserNotifications(
        authProvider.user!.id,
        refresh: true,
      );
    }
  }
}
