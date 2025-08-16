import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../services/api_service.dart';

class OneSignalService extends ChangeNotifier {
  static final OneSignalService _instance = OneSignalService._internal();
  factory OneSignalService() => _instance;
  OneSignalService._internal();

  bool _isInitialized = false;
  String? _playerId;
  String? _pushToken;

  // Getters
  bool get isInitialized => _isInitialized;
  String? get playerId => _playerId;
  String? get pushToken => _pushToken;

  /// Initialize OneSignal (FREE - No API key needed for basic setup)
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('OneSignal: Already initialized');
      return;
    }

    try {
      // Initialize OneSignal with your App ID from .env
      OneSignal.initialize('f6dbfa0d-b44d-4fce-9e63-c85c5b200d5d');

      // Request notification permissions
      final hasPermission = await OneSignal.Notifications.requestPermission(true);
      debugPrint('OneSignal: Permission granted: $hasPermission');

      // Setup listeners
      _setupListeners();

      // Get player ID and push token
      await _getPlayerInfo();

      _isInitialized = true;
      debugPrint('OneSignal: Initialized successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('OneSignal: Initialization error: $e');
      _isInitialized = false;
    }
  }

  /// Setup OneSignal listeners
  void _setupListeners() {
    // Handle notification received (foreground)
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      debugPrint('OneSignal: Notification received in foreground');
      // You can modify the notification here or prevent it from showing
      event.preventDefault();
      _showCustomNotification(event.notification);
    });

    // Handle notification clicked
    OneSignal.Notifications.addClickListener((event) {
      debugPrint('OneSignal: Notification clicked');
      _handleNotificationClick(event.notification);
    });

    // Handle permission changes
    OneSignal.Notifications.addPermissionObserver((state) {
      debugPrint('OneSignal: Permission changed to: $state');
    });

    // Handle subscription changes
    OneSignal.User.pushSubscription.addObserver((state) {
      debugPrint('OneSignal: Subscription changed');
      _playerId = state.current.id;
      _pushToken = state.current.token;

      if (_playerId != null) {
        _sendPlayerIdToServer(_playerId!);
      }
    });
  }

  /// Get player information
  Future<void> _getPlayerInfo() async {
    try {
      // Wait a bit for OneSignal to fully initialize
      await Future.delayed(const Duration(seconds: 2));
      
      final subscription = OneSignal.User.pushSubscription;
      _playerId = subscription.id;
      _pushToken = subscription.token;

      debugPrint('OneSignal: Player ID: $_playerId');
      debugPrint('OneSignal: Push Token: ${_pushToken != null ? '${_pushToken!.substring(0, 20)}...' : 'null'}');

      if (_playerId != null) {
        await _sendPlayerIdToServer(_playerId!);
      } else {
        debugPrint('OneSignal: Player ID is null, retrying in 3 seconds...');
        // Retry after a delay
        await Future.delayed(const Duration(seconds: 3));
        final retrySubscription = OneSignal.User.pushSubscription;
        _playerId = retrySubscription.id;
        _pushToken = retrySubscription.token;
        
        debugPrint('OneSignal: Retry - Player ID: $_playerId');
        
        if (_playerId != null) {
          await _sendPlayerIdToServer(_playerId!);
        } else {
          debugPrint('OneSignal: Player ID still null after retry');
        }
      }
    } catch (e) {
      debugPrint('OneSignal: Error getting player info: $e');
    }
  }

  /// Send player ID to your server
  Future<void> _sendPlayerIdToServer(String playerId) async {
    try {
      final response = await ApiService.post('/notifications/register', {
        'playerId': playerId,
        'pushToken': _pushToken,
        'platform': defaultTargetPlatform.name,
      });

      if (response['success'] == true) {
        debugPrint('OneSignal: Player ID sent to server successfully');
      } else {
        debugPrint(
            'OneSignal: Failed to send player ID: ${response['message']}');
      }
    } catch (e) {
      debugPrint('OneSignal: Error sending player ID to server: $e');
    }
  }

  /// Show custom notification (when app is in foreground)
  void _showCustomNotification(OSNotification notification) {
    // You can customize how notifications appear when app is open
    debugPrint('OneSignal: Showing notification: ${notification.title}');

    // For now, let the default behavior handle it
    OneSignal.Notifications.displayNotification(notification.notificationId);
  }

  /// Handle notification click
  void _handleNotificationClick(OSNotification notification) {
    final additionalData = notification.additionalData;

    if (additionalData != null) {
      final type = additionalData['type'] as String?;
      final bookingId = additionalData['bookingId'] as String?;

      debugPrint(
          'OneSignal: Handling click - Type: $type, BookingId: $bookingId');

      // Handle navigation based on notification type
      switch (type) {
        case 'booking_update':
          if (bookingId != null) {
            // Navigate to booking details
            debugPrint('OneSignal: Navigate to booking: $bookingId');
          }
          break;
        case 'payment_required':
          if (bookingId != null) {
            // Navigate to payment screen
            debugPrint('OneSignal: Navigate to payment: $bookingId');
          }
          break;
        default:
          debugPrint('OneSignal: Unknown notification type: $type');
      }
    }
  }

  /// Set user tags (for targeting)
  Future<void> setUserTags(Map<String, String> tags) async {
    try {
      OneSignal.User.addTags(tags);
      debugPrint('OneSignal: User tags set: $tags');
    } catch (e) {
      debugPrint('OneSignal: Error setting user tags: $e');
    }
  }

  /// Set user ID (link with your user system)
  Future<void> setUserId(String userId) async {
    try {
      OneSignal.login(userId);
      debugPrint('OneSignal: User ID set: $userId');
    } catch (e) {
      debugPrint('OneSignal: Error setting user ID: $e');
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      OneSignal.logout();
      _playerId = null;
      _pushToken = null;
      debugPrint('OneSignal: User logged out');
    } catch (e) {
      debugPrint('OneSignal: Error logging out: $e');
    }
  }

  /// Check if notifications are enabled
  bool get notificationsEnabled {
    return OneSignal.Notifications.permission;
  }

  /// Request notification permission
  Future<bool> requestPermission() async {
    try {
      return await OneSignal.Notifications.requestPermission(true);
    } catch (e) {
      debugPrint('OneSignal: Error requesting permission: $e');
      return false;
    }
  }

  /// Get notification permission status
  bool get hasPermission {
    return OneSignal.Notifications.permission;
  }

  /// Get notification preferences from server
  Future<Map<String, dynamic>?> getNotificationPreferences() async {
    try {
      final response = await ApiService.get('/notifications/preferences');

      if (response['success'] == true) {
        return response['preferences'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('OneSignal: Error getting notification preferences: $e');
      return null;
    }
  }

  /// Update notification preferences on server
  Future<bool> updateNotificationPreferences(
      Map<String, dynamic> preferences) async {
    try {
      final response =
          await ApiService.put('/notifications/preferences', preferences);

      if (response['success'] == true) {
        debugPrint('OneSignal: Notification preferences updated');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('OneSignal: Error updating notification preferences: $e');
      return false;
    }
  }
}
