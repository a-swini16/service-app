import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/notification_model.dart';
import 'local_database_service.dart';

class OfflineNotificationService extends ChangeNotifier {
  static final OfflineNotificationService _instance = OfflineNotificationService._internal();
  factory OfflineNotificationService() => _instance;
  OfflineNotificationService._internal();

  final LocalDatabaseService _localDb = LocalDatabaseService();
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  List<NotificationModel> _cachedNotifications = [];
  bool _isInitialized = false;

  // Getters
  List<NotificationModel> get cachedNotifications => _cachedNotifications;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Load cached notifications
      await _loadCachedNotifications();
      
      _isInitialized = true;
      debugPrint('OfflineNotificationService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize OfflineNotificationService: $e');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for iOS
    await _localNotifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    debugPrint('Notification tapped: ${response.payload}');
    
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        final notificationId = data['notification_id'] as String?;
        
        if (notificationId != null) {
          // Mark notification as read
          markNotificationAsRead(notificationId);
          
          // Handle deep linking or navigation based on notification type
          _handleNotificationAction(data);
        }
      } catch (e) {
        debugPrint('Failed to handle notification tap: $e');
      }
    }
  }

  void _handleNotificationAction(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final relatedBooking = data['related_booking'] as String?;
    
    // This would typically navigate to relevant screens
    // For now, just log the action
    debugPrint('Handling notification action: type=$type, booking=$relatedBooking');
  }

  Future<void> _loadCachedNotifications() async {
    try {
      _cachedNotifications = await _localDb.getAllNotifications();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load cached notifications: $e');
    }
  }

  // Create and store offline notification
  Future<NotificationModel?> createOfflineNotification({
    required String title,
    required String message,
    required String type,
    required String recipient,
    String? relatedBooking,
    String? relatedUser,
    String? relatedEmployee,
    String priority = 'medium',
    bool showLocalNotification = true,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final notificationId = 'offline_${DateTime.now().millisecondsSinceEpoch}';
      final now = DateTime.now();

      final notification = NotificationModel(
        id: notificationId,
        title: title,
        message: message,
        type: type,
        recipient: recipient,
        relatedBookingId: relatedBooking,
        relatedUserId: relatedUser,
        relatedEmployeeId: relatedEmployee,
        isRead: false,
        priority: priority,
        deliveryMethod: 'in_app',
        deliveryStatus: 'delivered',
        data: additionalData ?? {},
        actionRequired: _isActionRequired(type),
        actionUrl: _getActionUrl(type, relatedBooking),
        createdAt: now,
      );

      // Save to local database
      await _localDb.insertNotification(notification);
      
      // Update cached list
      _cachedNotifications.insert(0, notification);
      notifyListeners();

      // Show local notification if requested
      if (showLocalNotification) {
        await _showLocalNotification(notification);
      }

      return notification;
    } catch (e) {
      debugPrint('Failed to create offline notification: $e');
      return null;
    }
  }

  bool _isActionRequired(String type) {
    const actionRequiredTypes = [
      'booking_created',
      'booking_accepted',
      'booking_rejected',
      'worker_assigned',
      'service_completed',
      'payment_required',
    ];
    return actionRequiredTypes.contains(type);
  }

  String? _getActionUrl(String type, String? relatedBooking) {
    if (relatedBooking == null) return null;
    
    switch (type) {
      case 'booking_created':
      case 'booking_accepted':
      case 'booking_rejected':
      case 'worker_assigned':
      case 'service_completed':
        return '/booking-details?id=$relatedBooking';
      case 'payment_required':
        return '/payment?booking_id=$relatedBooking';
      default:
        return null;
    }
  }

  Future<void> _showLocalNotification(NotificationModel notification) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'om_enterprises_channel',
        'Om Enterprises Notifications',
        channelDescription: 'Notifications for Om Enterprises service bookings',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final payload = jsonEncode({
        'notification_id': notification.id,
        'type': notification.type,
        'related_booking': notification.relatedBookingId,
        'action_url': notification.actionUrl,
      });

      await _localNotifications.show(
        notification.id.hashCode,
        notification.title,
        notification.message,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Failed to show local notification: $e');
    }
  }

  // Mark notification as read
  Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      final index = _cachedNotifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        final updatedNotification = NotificationModel(
          id: _cachedNotifications[index].id,
          title: _cachedNotifications[index].title,
          message: _cachedNotifications[index].message,
          type: _cachedNotifications[index].type,
          recipient: _cachedNotifications[index].recipient,
          relatedBookingId: _cachedNotifications[index].relatedBookingId,
          relatedUserId: _cachedNotifications[index].relatedUserId,
          relatedEmployeeId: _cachedNotifications[index].relatedEmployeeId,
          isRead: true,
          readAt: DateTime.now(),
          priority: _cachedNotifications[index].priority,
          deliveryMethod: _cachedNotifications[index].deliveryMethod,
          deliveryStatus: _cachedNotifications[index].deliveryStatus,
          data: _cachedNotifications[index].data,
          actionRequired: _cachedNotifications[index].actionRequired,
          actionUrl: _cachedNotifications[index].actionUrl,
          createdAt: _cachedNotifications[index].createdAt,
        );

        // Update in local database
        await _localDb.updateNotification(updatedNotification);
        
        // Update cached list
        _cachedNotifications[index] = updatedNotification;
        notifyListeners();

        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Failed to mark notification as read: $e');
      return false;
    }
  }

  // Mark all notifications as read for a user
  Future<int> markAllNotificationsAsRead(String userId) async {
    int markedCount = 0;
    
    try {
      final userNotifications = getUserNotifications(userId);
      
      for (final notification in userNotifications) {
        if (!notification.isRead) {
          final success = await markNotificationAsRead(notification.id);
          if (success) markedCount++;
        }
      }
    } catch (e) {
      debugPrint('Failed to mark all notifications as read: $e');
    }
    
    return markedCount;
  }

  // Get notifications for a specific user
  List<NotificationModel> getUserNotifications(String userId) {
    return _cachedNotifications.where((notification) => 
        notification.recipient == userId || 
        notification.recipient == 'all').toList();
  }

  // Get unread notifications for a user
  List<NotificationModel> getUnreadNotifications(String userId) {
    return getUserNotifications(userId)
        .where((notification) => !notification.isRead)
        .toList();
  }

  // Get unread notification count
  int getUnreadNotificationCount(String userId) {
    return getUnreadNotifications(userId).length;
  }

  // Get notifications by type
  List<NotificationModel> getNotificationsByType(String type, {String? userId}) {
    var notifications = _cachedNotifications.where((n) => n.type == type);
    
    if (userId != null) {
      notifications = notifications.where((n) => 
          n.recipient == userId || n.recipient == 'all');
    }
    
    return notifications.toList();
  }

  // Get notifications related to a booking
  List<NotificationModel> getBookingNotifications(String bookingId, {String? userId}) {
    var notifications = _cachedNotifications.where((n) => n.relatedBookingId == bookingId);
    
    if (userId != null) {
      notifications = notifications.where((n) => 
          n.recipient == userId || n.recipient == 'all');
    }
    
    return notifications.toList();
  }

  // Search notifications
  List<NotificationModel> searchNotifications(String query, {String? userId}) {
    if (query.isEmpty) {
      return userId != null ? getUserNotifications(userId) : _cachedNotifications;
    }
    
    final lowerQuery = query.toLowerCase();
    var notifications = _cachedNotifications.where((notification) {
      return notification.title.toLowerCase().contains(lowerQuery) ||
             notification.message.toLowerCase().contains(lowerQuery) ||
             notification.type.toLowerCase().contains(lowerQuery);
    });
    
    if (userId != null) {
      notifications = notifications.where((n) => 
          n.recipient == userId || n.recipient == 'all');
    }
    
    return notifications.toList();
  }

  // Filter notifications by date range
  List<NotificationModel> filterNotificationsByDateRange(
    DateTime startDate, 
    DateTime endDate, 
    {String? userId}
  ) {
    var notifications = _cachedNotifications.where((notification) {
      final notificationDate = notification.createdAt;
      return notificationDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
             notificationDate.isBefore(endDate.add(const Duration(days: 1)));
    });
    
    if (userId != null) {
      notifications = notifications.where((n) => 
          n.recipient == userId || n.recipient == 'all');
    }
    
    return notifications.toList();
  }

  // Delete notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      final index = _cachedNotifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        // Remove from cached list
        _cachedNotifications.removeAt(index);
        notifyListeners();

        // Note: In a real implementation, you might want to mark as deleted
        // rather than actually deleting, for sync purposes
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Failed to delete notification: $e');
      return false;
    }
  }

  // Clear all notifications for a user
  Future<int> clearAllNotifications(String userId) async {
    int clearedCount = 0;
    
    try {
      final userNotifications = getUserNotifications(userId);
      
      for (final notification in userNotifications) {
        final success = await deleteNotification(notification.id);
        if (success) clearedCount++;
      }
    } catch (e) {
      debugPrint('Failed to clear all notifications: $e');
    }
    
    return clearedCount;
  }

  // Get notification statistics
  Map<String, dynamic> getNotificationStatistics({String? userId}) {
    final notifications = userId != null 
        ? getUserNotifications(userId) 
        : _cachedNotifications;
    
    final unreadCount = notifications.where((n) => !n.isRead).length;
    final readCount = notifications.where((n) => n.isRead).length;
    
    // Count by type
    final typeCounts = <String, int>{};
    for (final notification in notifications) {
      typeCounts[notification.type] = (typeCounts[notification.type] ?? 0) + 1;
    }
    
    // Count by priority
    final priorityCounts = <String, int>{};
    for (final notification in notifications) {
      priorityCounts[notification.priority] = (priorityCounts[notification.priority] ?? 0) + 1;
    }

    return {
      'total': notifications.length,
      'unread': unreadCount,
      'read': readCount,
      'by_type': typeCounts,
      'by_priority': priorityCounts,
    };
  }

  // Refresh cached notifications
  Future<void> refreshNotifications() async {
    await _loadCachedNotifications();
  }

  // Cancel local notification
  Future<void> cancelLocalNotification(String notificationId) async {
    try {
      await _localNotifications.cancel(notificationId.hashCode);
    } catch (e) {
      debugPrint('Failed to cancel local notification: $e');
    }
  }

  // Cancel all local notifications
  Future<void> cancelAllLocalNotifications() async {
    try {
      await _localNotifications.cancelAll();
    } catch (e) {
      debugPrint('Failed to cancel all local notifications: $e');
    }
  }

  // Schedule notification for later
  Future<void> scheduleNotification({
    required String title,
    required String message,
    required DateTime scheduledDate,
    String type = 'scheduled',
    String recipient = 'user',
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Create the notification record
      final notification = await createOfflineNotification(
        title: title,
        message: message,
        type: type,
        recipient: recipient,
        showLocalNotification: false, // Don't show immediately
        additionalData: additionalData,
      );

      if (notification != null) {
        // Schedule the local notification
        const androidDetails = AndroidNotificationDetails(
          'om_enterprises_scheduled',
          'Om Enterprises Scheduled Notifications',
          channelDescription: 'Scheduled notifications for Om Enterprises',
          importance: Importance.high,
          priority: Priority.high,
        );

        const iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

        const notificationDetails = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );

        final payload = jsonEncode({
          'notification_id': notification.id,
          'type': notification.type,
          'scheduled': true,
        });

        await _localNotifications.zonedSchedule(
          notification.id.hashCode,
          title,
          message,
          tz.TZDateTime.from(scheduledDate, tz.local),
          notificationDetails,
          payload: payload,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    } catch (e) {
      debugPrint('Failed to schedule notification: $e');
    }
  }
}