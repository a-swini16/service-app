import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/websocket_service.dart';
import '../services/service_completion_handler.dart';
import '../models/booking_model.dart';
import '../models/notification_model.dart';
import 'auth_provider.dart';

class WebSocketProvider extends ChangeNotifier {
  final WebSocketService _webSocketService = WebSocketService();
  final AuthProvider _authProvider;

  StreamSubscription<BookingStatusUpdate>? _bookingStatusSubscription;
  StreamSubscription<BookingModel>? _newBookingSubscription;
  StreamSubscription<WorkerAssignment>? _workerAssignmentSubscription;
  StreamSubscription<PaymentNotification>? _paymentSubscription;
  StreamSubscription<NotificationModel>? _notificationSubscription;
  StreamSubscription<ConnectionStatus>? _connectionSubscription;

  // Connection state
  bool _isConnected = false;
  bool _isConnecting = false;
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  String? _lastError;

  // Real-time data
  final List<BookingStatusUpdate> _recentStatusUpdates = [];
  final List<NotificationModel> _recentNotifications = [];
  final List<PaymentNotification> _recentPaymentNotifications = [];

  WebSocketProvider(this._authProvider) {
    _setupEventListeners();

    // Auto-connect when user is authenticated
    _authProvider.addListener(_handleAuthStateChange);
  }

  // Getters
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  ConnectionStatus get connectionStatus => _connectionStatus;
  String? get lastError => _lastError;
  List<BookingStatusUpdate> get recentStatusUpdates =>
      List.unmodifiable(_recentStatusUpdates);
  List<NotificationModel> get recentNotifications =>
      List.unmodifiable(_recentNotifications);
  List<PaymentNotification> get recentPaymentNotifications =>
      List.unmodifiable(_recentPaymentNotifications);

  // Event streams (pass-through from WebSocketService)
  Stream<BookingStatusUpdate> get bookingStatusUpdates =>
      _webSocketService.bookingStatusUpdates;
  Stream<BookingModel> get newBookings => _webSocketService.newBookings;
  Stream<WorkerAssignment> get workerAssignments =>
      _webSocketService.workerAssignments;
  Stream<PaymentNotification> get paymentNotifications =>
      _webSocketService.paymentNotifications;
  Stream<NotificationModel> get notifications =>
      _webSocketService.notifications;

  void _setupEventListeners() {
    // Listen to connection status changes
    _connectionSubscription =
        _webSocketService.connectionStatus.listen((status) {
      _connectionStatus = status;
      _isConnected = status == ConnectionStatus.connected;
      _isConnecting = status == ConnectionStatus.connecting;

      if (status == ConnectionStatus.error ||
          status == ConnectionStatus.failed) {
        _lastError = 'Connection failed';
      } else {
        _lastError = null;
      }

      notifyListeners();
    });

    // Listen to booking status updates
    _bookingStatusSubscription =
        _webSocketService.bookingStatusUpdates.listen((update) {
      _recentStatusUpdates.insert(0, update);
      if (_recentStatusUpdates.length > 50) {
        _recentStatusUpdates.removeLast();
      }
      
      // Handle service completion for automatic payment navigation
      ServiceCompletionHandler.handleBookingStatusUpdate(
        bookingId: update.bookingId,
        newStatus: update.newStatus,
        oldStatus: update.previousStatus,
        additionalData: {
          'actualAmount': update.booking.actualAmount,
          'paymentAmount': update.booking.paymentAmount,
          'serviceType': update.booking.serviceType,
          'customerName': update.booking.customerName,
          'message': update.message,
        },
      );
      
      notifyListeners();
    });

    // Listen to new bookings (for admins)
    _newBookingSubscription = _webSocketService.newBookings.listen((booking) {
      debugPrint('WebSocketProvider: New booking received: ${booking.id}');
      notifyListeners();
    });

    // Listen to worker assignments
    _workerAssignmentSubscription =
        _webSocketService.workerAssignments.listen((assignment) {
      debugPrint(
          'WebSocketProvider: Worker assigned: ${assignment.worker.name}');
      notifyListeners();
    });

    // Listen to payment notifications
    _paymentSubscription =
        _webSocketService.paymentNotifications.listen((payment) {
      _recentPaymentNotifications.insert(0, payment);
      if (_recentPaymentNotifications.length > 20) {
        _recentPaymentNotifications.removeLast();
      }
      notifyListeners();
    });

    // Listen to notifications
    _notificationSubscription =
        _webSocketService.notifications.listen((notification) {
      _recentNotifications.insert(0, notification);
      if (_recentNotifications.length > 100) {
        _recentNotifications.removeLast();
      }
      
      // Handle payment required notifications for automatic navigation
      if (notification.type == 'payment_required' || 
          notification.actionRequired == true) {
        ServiceCompletionHandler.handlePaymentRequiredNotification(
          notification: notification,
        );
      }
      
      notifyListeners();
    });
  }

  void _handleAuthStateChange() {
    if (_authProvider.isLoggedIn && _authProvider.accessToken != null) {
      // User logged in, connect to WebSocket
      connect();
    } else {
      // User logged out, disconnect from WebSocket
      disconnect();
    }
  }

  // Connect to WebSocket
  Future<void> connect({String? baseUrl}) async {
    if (!_authProvider.isLoggedIn || _authProvider.accessToken == null) {
      debugPrint('WebSocketProvider: Cannot connect - user not authenticated');
      return;
    }

    try {
      final userType = _authProvider.isAdmin ? 'admin' : 'user';

      await _webSocketService.connect(
        token: _authProvider.accessToken!,
        userType: userType,
        baseUrl: baseUrl,
      );

      debugPrint('WebSocketProvider: Connection initiated');
    } catch (e) {
      debugPrint('WebSocketProvider: Connection error: $e');
      _lastError = e.toString();
      notifyListeners();
    }
  }

  // Disconnect from WebSocket
  void disconnect() {
    _webSocketService.disconnect();
    _clearRecentData();
    debugPrint('WebSocketProvider: Disconnected');
  }

  // Subscribe to specific booking updates
  void subscribeToBookingUpdates(String bookingId) {
    _webSocketService.subscribeToBookingUpdates(bookingId);
  }

  // Unsubscribe from specific booking updates
  void unsubscribeFromBookingUpdates(String bookingId) {
    _webSocketService.unsubscribeFromBookingUpdates(bookingId);
  }

  // Get booking status update for specific booking
  BookingStatusUpdate? getLatestStatusUpdate(String bookingId) {
    try {
      return _recentStatusUpdates.firstWhere(
        (update) => update.bookingId == bookingId,
      );
    } catch (e) {
      return null;
    }
  }

  // Get recent notifications for specific type
  List<NotificationModel> getNotificationsByType(String type) {
    return _recentNotifications.where((n) => n.type == type).toList();
  }

  // Get recent payment notifications for specific booking
  List<PaymentNotification> getPaymentNotifications(String bookingId) {
    return _recentPaymentNotifications
        .where((p) => p.bookingId == bookingId)
        .toList();
  }

  // Clear recent data
  void _clearRecentData() {
    _recentStatusUpdates.clear();
    _recentNotifications.clear();
    _recentPaymentNotifications.clear();
    notifyListeners();
  }

  // Get connection statistics
  Map<String, dynamic> getConnectionStats() {
    return {
      ..._webSocketService.getConnectionStats(),
      'recentStatusUpdates': _recentStatusUpdates.length,
      'recentNotifications': _recentNotifications.length,
      'recentPaymentNotifications': _recentPaymentNotifications.length,
    };
  }

  // Retry connection
  Future<void> retryConnection() async {
    if (_isConnecting || _isConnected) {
      return;
    }

    _lastError = null;
    notifyListeners();

    await connect();
  }

  // Check if specific booking has recent updates
  bool hasRecentUpdates(String bookingId, {Duration? within}) {
    final timeLimit = within ?? const Duration(minutes: 5);
    final cutoff = DateTime.now().subtract(timeLimit);

    return _recentStatusUpdates.any((update) =>
        update.bookingId == bookingId && update.timestamp.isAfter(cutoff));
  }

  // Get unread notification count
  int get unreadNotificationCount {
    return _recentNotifications.where((n) => !n.isRead).length;
  }

  // Mark notification as read (local state only)
  void markNotificationAsRead(String notificationId) {
    final index =
        _recentNotifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      // Create a new notification with isRead = true
      final notification = _recentNotifications[index];
      final updatedNotification = NotificationModel(
        id: notification.id,
        title: notification.title,
        message: notification.message,
        type: notification.type,
        recipient: notification.recipient,
        relatedBookingId: notification.relatedBookingId,
        relatedUserId: notification.relatedUserId,
        relatedEmployeeId: notification.relatedEmployeeId,
        priority: notification.priority,
        deliveryMethod: notification.deliveryMethod,
        actionRequired: notification.actionRequired,
        actionUrl: notification.actionUrl,
        data: notification.data,
        isRead: true,
        readAt: DateTime.now(),
        createdAt: notification.createdAt,
      );

      _recentNotifications[index] = updatedNotification;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authProvider.removeListener(_handleAuthStateChange);
    _connectionSubscription?.cancel();
    _bookingStatusSubscription?.cancel();
    _newBookingSubscription?.cancel();
    _workerAssignmentSubscription?.cancel();
    _paymentSubscription?.cancel();
    _notificationSubscription?.cancel();
    _webSocketService.dispose();
    super.dispose();
  }
}
