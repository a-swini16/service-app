import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = true;
  String _currentUserType = 'admin'; // admin, user, worker
  String? _currentUserId;
  String _selectedFilter = 'all'; // all, unread, workflow, system
  String _selectedWorkflowStage = 'all'; // all, booking, assignment, service, payment

  List<NotificationModel> get notifications => _getFilteredNotifications();
  List<NotificationModel> get allNotifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  int get currentPage => _currentPage;
  bool get hasMore => _hasMore;
  String get currentUserType => _currentUserType;
  String? get currentUserId => _currentUserId;
  String get selectedFilter => _selectedFilter;
  String get selectedWorkflowStage => _selectedWorkflowStage;

  // Fetch admin notifications
  Future<void> fetchNotifications({bool refresh = false}) async {
    _currentUserType = 'admin';
    
    if (refresh) {
      _currentPage = 1;
      _notifications.clear();
      _hasMore = true;
    }

    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    notifyListeners();

    try {
      final result = await NotificationService.getAdminNotifications(
        page: _currentPage,
        limit: 20,
      );

      if (result['success']) {
        final newNotifications = result['notifications'] as List<NotificationModel>;
        
        if (refresh) {
          _notifications = newNotifications;
        } else {
          _notifications.addAll(newNotifications);
        }

        _unreadCount = result['unreadCount'] ?? 0;
        _totalPages = result['totalPages'] ?? 1;
        _hasMore = _currentPage < _totalPages;
        
        if (_hasMore) {
          _currentPage++;
        }
      }
    } catch (e) {
      print('Error fetching notifications: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Fetch user notifications
  Future<void> fetchUserNotifications(String userId, {bool refresh = false}) async {
    _currentUserType = 'user';
    _currentUserId = userId;
    
    if (refresh) {
      _currentPage = 1;
      _notifications.clear();
      _hasMore = true;
    }

    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    notifyListeners();

    try {
      final result = await NotificationService.getUserNotifications(
        userId,
        page: _currentPage,
        limit: 20,
        unreadOnly: _selectedFilter == 'unread',
      );

      if (result['success']) {
        final newNotifications = result['notifications'] as List<NotificationModel>;
        
        if (refresh) {
          _notifications = newNotifications;
        } else {
          _notifications.addAll(newNotifications);
        }

        _unreadCount = result['unreadCount'] ?? 0;
        _totalPages = result['totalPages'] ?? 1;
        _hasMore = _currentPage < _totalPages;
        
        if (_hasMore) {
          _currentPage++;
        }
      }
    } catch (e) {
      print('Error fetching user notifications: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Fetch worker notifications
  Future<void> fetchWorkerNotifications(String workerId, {bool refresh = false}) async {
    _currentUserType = 'worker';
    _currentUserId = workerId;
    
    if (refresh) {
      _currentPage = 1;
      _notifications.clear();
      _hasMore = true;
    }

    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    notifyListeners();

    try {
      final result = await NotificationService.getWorkerNotifications(
        workerId,
        page: _currentPage,
        limit: 20,
        unreadOnly: _selectedFilter == 'unread',
      );

      if (result['success']) {
        final newNotifications = result['notifications'] as List<NotificationModel>;
        
        if (refresh) {
          _notifications = newNotifications;
        } else {
          _notifications.addAll(newNotifications);
        }

        _unreadCount = result['unreadCount'] ?? 0;
        _totalPages = result['totalPages'] ?? 1;
        _hasMore = _currentPage < _totalPages;
        
        if (_hasMore) {
          _currentPage++;
        }
      }
    } catch (e) {
      print('Error fetching worker notifications: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Fetch unread count only
  Future<void> fetchUnreadCount() async {
    try {
      _unreadCount = await NotificationService.getUnreadCount();
      notifyListeners();
    } catch (e) {
      print('Error fetching unread count: $e');
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final success = await NotificationService.markAsRead(notificationId);
      
      if (success) {
        // Update local notification
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1 && !_notifications[index].isRead) {
          final oldNotification = _notifications[index];
          _notifications[index] = NotificationModel(
            id: oldNotification.id,
            title: oldNotification.title,
            message: oldNotification.message,
            type: oldNotification.type,
            recipient: oldNotification.recipient,
            relatedBookingId: oldNotification.relatedBookingId,
            relatedUserId: oldNotification.relatedUserId,
            relatedEmployeeId: oldNotification.relatedEmployeeId,
            isRead: true,
            readAt: DateTime.now(),
            deliveredAt: oldNotification.deliveredAt,
            priority: oldNotification.priority,
            deliveryMethod: oldNotification.deliveryMethod,
            deliveryStatus: oldNotification.deliveryStatus,
            actionRequired: oldNotification.actionRequired,
            actionUrl: oldNotification.actionUrl,
            data: oldNotification.data,
            createdAt: oldNotification.createdAt,
          );
          
          _unreadCount = (_unreadCount - 1).clamp(0, _unreadCount);
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final success = await NotificationService.markAllAsRead();
      
      if (success) {
        // Update all local notifications
        _notifications = _notifications.map((notification) {
          if (!notification.isRead) {
            return NotificationModel(
              id: notification.id,
              title: notification.title,
              message: notification.message,
              type: notification.type,
              recipient: notification.recipient,
              relatedBookingId: notification.relatedBookingId,
              relatedUserId: notification.relatedUserId,
              relatedEmployeeId: notification.relatedEmployeeId,
              isRead: true,
              readAt: DateTime.now(),
              deliveredAt: notification.deliveredAt,
              priority: notification.priority,
              deliveryMethod: notification.deliveryMethod,
              deliveryStatus: notification.deliveryStatus,
              actionRequired: notification.actionRequired,
              actionUrl: notification.actionUrl,
              data: notification.data,
              createdAt: notification.createdAt,
            );
          }
          return notification;
        }).toList();
        
        _unreadCount = 0;
        notifyListeners();
      }
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  // Create test notification
  Future<void> createTestNotification() async {
    try {
      final success = await NotificationService.createTestNotification();
      
      if (success) {
        // Refresh notifications to show the new test notification
        await fetchNotifications(refresh: true);
      }
    } catch (e) {
      print('Error creating test notification: $e');
    }
  }

  // Get notifications by type
  List<NotificationModel> getNotificationsByType(String type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  // Get unread notifications
  List<NotificationModel> getUnreadNotifications() {
    return _notifications.where((n) => !n.isRead).toList();
  }

  // Clear all notifications (local only)
  void clearNotifications() {
    _notifications.clear();
    _unreadCount = 0;
    _currentPage = 1;
    _hasMore = true;
    notifyListeners();
  }

  // Set notification filter
  void setFilter(String filter) {
    if (_selectedFilter != filter) {
      _selectedFilter = filter;
      notifyListeners();
    }
  }

  // Set workflow stage filter
  void setWorkflowStageFilter(String stage) {
    if (_selectedWorkflowStage != stage) {
      _selectedWorkflowStage = stage;
      notifyListeners();
    }
  }

  // Get filtered notifications
  List<NotificationModel> _getFilteredNotifications() {
    List<NotificationModel> filtered = _notifications;

    // Apply basic filter
    switch (_selectedFilter) {
      case 'unread':
        filtered = filtered.where((n) => !n.isRead).toList();
        break;
      case 'workflow':
        filtered = filtered.where((n) => n.isWorkflowNotification).toList();
        break;
      case 'system':
        filtered = filtered.where((n) => n.type == 'system').toList();
        break;
      case 'actionable':
        filtered = filtered.where((n) => n.isActionable).toList();
        break;
      default:
        // 'all' - no additional filtering
        break;
    }

    // Apply workflow stage filter
    if (_selectedWorkflowStage != 'all') {
      filtered = NotificationService.filterByWorkflowStage(filtered, _selectedWorkflowStage);
    }

    return filtered;
  }

  // Handle notification action
  String? handleNotificationAction(NotificationModel notification) {
    if (!notification.isActionable) return null;

    // Mark as read when action is taken
    markAsRead(notification.id);

    // Return navigation route
    return NotificationService.getNavigationRoute(notification);
  }

  // Get navigation arguments for notification
  Map<String, dynamic>? getNavigationArguments(NotificationModel notification) {
    return NotificationService.getNavigationArguments(notification);
  }

  // Get workflow notifications grouped by stage
  Map<String, List<NotificationModel>> getWorkflowNotificationsByStage() {
    final workflowNotifications = _notifications.where((n) => n.isWorkflowNotification).toList();
    
    return {
      'booking': NotificationService.filterByWorkflowStage(workflowNotifications, 'booking'),
      'assignment': NotificationService.filterByWorkflowStage(workflowNotifications, 'assignment'),
      'service': NotificationService.filterByWorkflowStage(workflowNotifications, 'service'),
      'payment': NotificationService.filterByWorkflowStage(workflowNotifications, 'payment'),
    };
  }

  // Get notification statistics
  Map<String, dynamic> getNotificationStats() {
    final priorityCounts = NotificationService.getNotificationPriorityCount(_notifications);
    final unreadNotifications = _notifications.where((n) => !n.isRead).toList();
    final workflowNotifications = _notifications.where((n) => n.isWorkflowNotification).toList();
    final actionableNotifications = _notifications.where((n) => n.isActionable).toList();

    return {
      'total': _notifications.length,
      'unread': unreadNotifications.length,
      'workflow': workflowNotifications.length,
      'actionable': actionableNotifications.length,
      'priorityCounts': priorityCounts,
      'unreadPriorityCounts': NotificationService.getNotificationPriorityCount(unreadNotifications),
    };
  }

  // Subscribe to real-time notifications
  void subscribeToRealTimeNotifications() {
    if (_currentUserId != null) {
      NotificationService.subscribeToNotifications(_currentUserId!, _currentUserType);
      
      // TODO: Listen to notification stream and update local state
      // NotificationService.getNotificationStream().listen((notification) {
      //   _notifications.insert(0, notification);
      //   if (!notification.isRead) {
      //     _unreadCount++;
      //   }
      //   notifyListeners();
      // });
    }
  }

  // Unsubscribe from real-time notifications
  void unsubscribeFromRealTimeNotifications() {
    NotificationService.unsubscribeFromNotifications();
  }

  // Refresh current notifications based on user type
  Future<void> refreshCurrentNotifications() async {
    switch (_currentUserType) {
      case 'admin':
        await fetchNotifications(refresh: true);
        break;
      case 'user':
        if (_currentUserId != null) {
          await fetchUserNotifications(_currentUserId!, refresh: true);
        }
        break;
      case 'worker':
        if (_currentUserId != null) {
          await fetchWorkerNotifications(_currentUserId!, refresh: true);
        }
        break;
    }
  }

  // Add new notification (for real-time updates)
  void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    if (!notification.isRead) {
      _unreadCount++;
    }
    notifyListeners();
  }

  // Update notification (for real-time updates)
  void updateNotification(NotificationModel updatedNotification) {
    final index = _notifications.indexWhere((n) => n.id == updatedNotification.id);
    if (index != -1) {
      final wasUnread = !_notifications[index].isRead;
      final isUnreadNow = !updatedNotification.isRead;
      
      _notifications[index] = updatedNotification;
      
      // Update unread count
      if (wasUnread && !isUnreadNow) {
        _unreadCount = (_unreadCount - 1).clamp(0, _unreadCount);
      } else if (!wasUnread && isUnreadNow) {
        _unreadCount++;
      }
      
      notifyListeners();
    }
  }
}