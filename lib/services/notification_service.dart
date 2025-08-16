import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import '../models/notification_model.dart';

class NotificationService {
  static const _storage = FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Get admin notifications
  static Future<Map<String, dynamic>> getAdminNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final uri = Uri.parse('${AppConstants.baseUrl}/notifications/admin')
          .replace(queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      });

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          final notificationsList = (data['notifications'] as List)
              .map((notification) => NotificationModel.fromJson(notification))
              .toList();

          return {
            'success': true,
            'notifications': notificationsList,
            'total': data['total'] ?? 0,
            'unreadCount': data['unreadCount'] ?? 0,
            'currentPage': data['currentPage'] ?? 1,
            'totalPages': data['totalPages'] ?? 1,
          };
        }
      }

      return {
        'success': false,
        'notifications': [],
        'total': 0,
        'unreadCount': 0,
        'currentPage': 1,
        'totalPages': 1,
      };
    } catch (e) {
      return {
        'success': false,
        'notifications': [],
        'total': 0,
        'unreadCount': 0,
        'currentPage': 1,
        'totalPages': 1,
        'error': e.toString(),
      };
    }
  }

  // Get user notifications
  static Future<Map<String, dynamic>> getUserNotifications(
    String userId, {
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final uri =
          Uri.parse('${AppConstants.baseUrl}/notifications/user/$userId')
              .replace(queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
        'unreadOnly': unreadOnly.toString(),
      });

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          final notificationsList = (data['notifications'] as List)
              .map((notification) => NotificationModel.fromJson(notification))
              .toList();

          return {
            'success': true,
            'notifications': notificationsList,
            'total': data['total'] ?? 0,
            'unreadCount': data['unreadCount'] ?? 0,
            'currentPage': data['currentPage'] ?? 1,
            'totalPages': data['totalPages'] ?? 1,
          };
        }
      }

      return {
        'success': false,
        'notifications': [],
        'total': 0,
        'unreadCount': 0,
        'currentPage': 1,
        'totalPages': 1,
      };
    } catch (e) {
      return {
        'success': false,
        'notifications': [],
        'total': 0,
        'unreadCount': 0,
        'currentPage': 1,
        'totalPages': 1,
        'error': e.toString(),
      };
    }
  }

  // Get worker notifications
  static Future<Map<String, dynamic>> getWorkerNotifications(
    String workerId, {
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final uri =
          Uri.parse('${AppConstants.baseUrl}/notifications/worker/$workerId')
              .replace(queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
        'unreadOnly': unreadOnly.toString(),
      });

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          final notificationsList = (data['notifications'] as List)
              .map((notification) => NotificationModel.fromJson(notification))
              .toList();

          return {
            'success': true,
            'notifications': notificationsList,
            'total': data['total'] ?? 0,
            'unreadCount': data['unreadCount'] ?? 0,
            'currentPage': data['currentPage'] ?? 1,
            'totalPages': data['totalPages'] ?? 1,
          };
        }
      }

      return {
        'success': false,
        'notifications': [],
        'total': 0,
        'unreadCount': 0,
        'currentPage': 1,
        'totalPages': 1,
      };
    } catch (e) {
      return {
        'success': false,
        'notifications': [],
        'total': 0,
        'unreadCount': 0,
        'currentPage': 1,
        'totalPages': 1,
        'error': e.toString(),
      };
    }
  }

  // Mark notification as read
  static Future<bool> markAsRead(String notificationId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/notifications/$notificationId/read'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Mark all notifications as read
  static Future<bool> markAllAsRead() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/notifications/admin/read-all'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Get unread count
  static Future<int> getUnreadCount() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/notifications/admin/unread-count'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['unreadCount'] ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // Create test notification (for development)
  static Future<bool> createTestNotification() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/notifications/test'),
        headers: headers,
        body: jsonEncode({
          'title': '🧪 Test Notification',
          'message':
              'This is a test notification to verify the system is working.',
          'type': 'system',
          'priority': 'medium',
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Get notification statistics
  static Future<Map<String, dynamic>> getNotificationStats() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/notifications/admin/stats'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      }

      return {
        'success': false,
        'total': 0,
        'unread': 0,
        'today': 0,
        'thisWeek': 0,
        'thisMonth': 0,
      };
    } catch (e) {
      return {
        'success': false,
        'total': 0,
        'unread': 0,
        'today': 0,
        'thisWeek': 0,
        'thisMonth': 0,
        'error': e.toString(),
      };
    }
  }

  // Delete notification
  static Future<bool> deleteNotification(String notificationId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}/notifications/$notificationId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Clear all notifications
  static Future<bool> clearAllNotifications() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}/notifications/admin/clear-all'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Get notifications by type
  static Future<Map<String, dynamic>> getNotificationsByType(
    String type, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final uri =
          Uri.parse('${AppConstants.baseUrl}/notifications/admin/type/$type')
              .replace(queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      });

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          final notificationsList = (data['notifications'] as List)
              .map((notification) => NotificationModel.fromJson(notification))
              .toList();

          return {
            'success': true,
            'notifications': notificationsList,
            'total': data['total'] ?? 0,
            'currentPage': data['currentPage'] ?? 1,
            'totalPages': data['totalPages'] ?? 1,
          };
        }
      }

      return {
        'success': false,
        'notifications': [],
        'total': 0,
        'currentPage': 1,
        'totalPages': 1,
      };
    } catch (e) {
      return {
        'success': false,
        'notifications': [],
        'total': 0,
        'currentPage': 1,
        'totalPages': 1,
        'error': e.toString(),
      };
    }
  }

  // Search notifications
  static Future<Map<String, dynamic>> searchNotifications(
    String query, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final uri =
          Uri.parse('${AppConstants.baseUrl}/notifications/admin/search')
              .replace(queryParameters: {
        'q': query,
        'page': page.toString(),
        'limit': limit.toString(),
      });

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          final notificationsList = (data['notifications'] as List)
              .map((notification) => NotificationModel.fromJson(notification))
              .toList();

          return {
            'success': true,
            'notifications': notificationsList,
            'total': data['total'] ?? 0,
            'currentPage': data['currentPage'] ?? 1,
            'totalPages': data['totalPages'] ?? 1,
          };
        }
      }

      return {
        'success': false,
        'notifications': [],
        'total': 0,
        'currentPage': 1,
        'totalPages': 1,
      };
    } catch (e) {
      return {
        'success': false,
        'notifications': [],
        'total': 0,
        'currentPage': 1,
        'totalPages': 1,
        'error': e.toString(),
      };
    }
  }

  // Handle notification action (deep linking)
  static String? getNavigationRoute(NotificationModel notification) {
    if (!notification.isActionable) return null;

    final actionUrl = notification.actionUrl!;

    // Map backend action URLs to Flutter routes
    switch (actionUrl) {
      case '/admin/bookings':
        return '/admin-panel';
      case '/bookings/status':
        return '/user-booking-status';
      case '/bookings/history':
        return '/user-booking-status';
      case '/payment':
        return '/payment/${notification.relatedBookingId}';
      case '/payment/retry':
        return '/payment/${notification.relatedBookingId}';
      case '/admin/payments':
        return '/admin-panel';
      case '/worker/assignments':
        return '/worker-assignments';
      default:
        return null;
    }
  }

  // Get notification action parameters
  static Map<String, dynamic>? getNavigationArguments(
      NotificationModel notification) {
    if (!notification.isActionable) return null;

    return {
      'notificationId': notification.id,
      'bookingId': notification.relatedBookingId,
      'userId': notification.relatedUserId,
      'workerId': notification.relatedEmployeeId,
      'notificationType': notification.type,
      'data': notification.data,
    };
  }

  // Create workflow notification (for testing)
  static Future<bool> createWorkflowNotification({
    required String bookingId,
    required String notificationType,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/notifications/test-workflow'),
        headers: headers,
        body: jsonEncode({
          'bookingId': bookingId,
          'notificationType': notificationType,
          'additionalData': additionalData ?? {},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Create notification
  static Future<bool> createNotification(
      Map<String, dynamic> notificationData) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/notifications'),
        headers: headers,
        body: jsonEncode(notificationData),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error creating notification: $e');
      return false;
    }
  }

  // Create notification for specific user
  static Future<bool> createUserNotification(
    String userId,
    Map<String, dynamic> notificationData,
  ) async {
    try {
      final headers = await _getAuthHeaders();
      final data = {
        ...notificationData,
        'recipientId': userId,
        'recipientType': 'user',
      };

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/notifications/user'),
        headers: headers,
        body: jsonEncode(data),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return responseData['success'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error creating user notification: $e');
      return false;
    }
  }

  // Create notification for admin
  static Future<bool> createAdminNotification(
    Map<String, dynamic> notificationData,
  ) async {
    try {
      final headers = await _getAuthHeaders();
      final data = {
        ...notificationData,
        'recipientType': 'admin',
      };

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/notifications/admin'),
        headers: headers,
        body: jsonEncode(data),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return responseData['success'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error creating admin notification: $e');
      return false;
    }
  }

  // Get real-time notification updates (placeholder for WebSocket implementation)
  static Stream<NotificationModel>? _notificationStream;

  static Stream<NotificationModel> getNotificationStream() {
    // TODO: Implement WebSocket connection for real-time notifications
    // This would connect to a WebSocket endpoint and listen for new notifications

    // For now, return an empty stream
    _notificationStream ??= Stream.empty();
    return _notificationStream!;
  }

  // Subscribe to real-time notifications
  static void subscribeToNotifications(String userId, String userType) {
    // TODO: Implement WebSocket subscription
    // This would establish a WebSocket connection and listen for notifications
    // specific to the user and user type (admin, user, worker)

    print('Subscribing to notifications for $userType: $userId');
  }

  // Unsubscribe from real-time notifications
  static void unsubscribeFromNotifications() {
    // TODO: Implement WebSocket unsubscription
    // This would close the WebSocket connection

    print('Unsubscribing from notifications');
  }

  // Filter notifications by workflow stage
  static List<NotificationModel> filterByWorkflowStage(
    List<NotificationModel> notifications,
    String stage,
  ) {
    final stageTypes = <String, List<String>>{
      'booking': [
        'booking_created',
        'booking_accepted',
        'booking_rejected',
        'booking_updated',
        'booking_cancelled'
      ],
      'assignment': [
        'worker_assigned',
        'worker_assigned_admin',
        'worker_assigned_worker'
      ],
      'service': [
        'service_started',
        'service_in_progress',
        'service_completed',
        'service_completed_admin'
      ],
      'payment': ['payment_required', 'payment_received', 'payment_failed'],
      'reminders': ['service_reminder', 'payment_reminder'],
    };

    final types = stageTypes[stage] ?? [];
    return notifications.where((n) => types.contains(n.type)).toList();
  }

  // Get notification priority count
  static Map<String, int> getNotificationPriorityCount(
      List<NotificationModel> notifications) {
    final counts = <String, int>{
      'urgent': 0,
      'high': 0,
      'medium': 0,
      'low': 0,
    };

    for (final notification in notifications) {
      counts[notification.priority] = (counts[notification.priority] ?? 0) + 1;
    }

    return counts;
  }
}
