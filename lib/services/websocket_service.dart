import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter/foundation.dart';
import '../models/booking_model.dart';
import '../models/notification_model.dart';

class WebSocketService extends ChangeNotifier {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  io.Socket? _socket;
  bool _isConnected = false;
  bool _isConnecting = false;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);
  static const Duration _heartbeatInterval = Duration(seconds: 30);

  // Event streams
  final StreamController<BookingStatusUpdate> _bookingStatusController =
      StreamController<BookingStatusUpdate>.broadcast();
  final StreamController<BookingModel> _newBookingController =
      StreamController<BookingModel>.broadcast();
  final StreamController<WorkerAssignment> _workerAssignmentController =
      StreamController<WorkerAssignment>.broadcast();
  final StreamController<PaymentNotification> _paymentController =
      StreamController<PaymentNotification>.broadcast();
  final StreamController<NotificationModel> _notificationController =
      StreamController<NotificationModel>.broadcast();
  final StreamController<ConnectionStatus> _connectionController =
      StreamController<ConnectionStatus>.broadcast();

  // Getters
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;

  // Event streams
  Stream<BookingStatusUpdate> get bookingStatusUpdates =>
      _bookingStatusController.stream;
  Stream<BookingModel> get newBookings => _newBookingController.stream;
  Stream<WorkerAssignment> get workerAssignments =>
      _workerAssignmentController.stream;
  Stream<PaymentNotification> get paymentNotifications =>
      _paymentController.stream;
  Stream<NotificationModel> get notifications => _notificationController.stream;
  Stream<ConnectionStatus> get connectionStatus => _connectionController.stream;

  // Initialize WebSocket connection
  Future<void> connect({
    required String token,
    required String userType,
    String? baseUrl,
  }) async {
    if (_isConnected || _isConnecting) {
      debugPrint('WebSocket: Already connected or connecting');
      return;
    }

    _isConnecting = true;
    _connectionController.add(ConnectionStatus.connecting);
    notifyListeners();

    try {
      final serverUrl = baseUrl ?? 'http://10.0.2.2:5000';

      debugPrint('WebSocket: Connecting to $serverUrl');

      _socket = io.io(
          serverUrl,
          io.OptionBuilder()
              .setTransports(['websocket', 'polling'])
              .enableAutoConnect()
              .enableReconnection()
              .setReconnectionAttempts(5)
              .setReconnectionDelay(3000)
              .build());

      _setupEventHandlers();

      // Authenticate after connection
      _socket!.onConnect((_) {
        debugPrint('WebSocket: Connected to server');
        _authenticate(token, userType);
      });

      _socket!.connect();
    } catch (e) {
      debugPrint('WebSocket: Connection error: $e');
      _isConnecting = false;
      _connectionController.add(ConnectionStatus.disconnected);
      notifyListeners();
      _scheduleReconnect(token, userType, baseUrl);
    }
  }

  // Authenticate with the server
  void _authenticate(String token, String userType) {
    if (_socket == null) return;

    debugPrint('WebSocket: Authenticating as $userType');
    _socket!.emit('authenticate', {
      'token': token,
      'userType': userType,
    });
  }

  // Setup event handlers
  void _setupEventHandlers() {
    if (_socket == null) return;

    // Connection events
    _socket!.onConnect((_) {
      debugPrint('WebSocket: Connected');
      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0;
      _connectionController.add(ConnectionStatus.connected);
      _startHeartbeat();
      notifyListeners();
    });

    _socket!.onDisconnect((_) {
      debugPrint('WebSocket: Disconnected');
      _isConnected = false;
      _isConnecting = false;
      _connectionController.add(ConnectionStatus.disconnected);
      _stopHeartbeat();
      notifyListeners();
    });

    _socket!.onConnectError((error) {
      debugPrint('WebSocket: Connection error: $error');
      _isConnected = false;
      _isConnecting = false;
      _connectionController.add(ConnectionStatus.error);
      notifyListeners();
    });

    // Authentication events
    _socket!.on('authenticated', (data) {
      debugPrint('WebSocket: Authenticated successfully');
      final response = data as Map<String, dynamic>;
      if (response['success'] == true) {
        debugPrint(
            'WebSocket: User ${response['userId']} authenticated as ${response['userType']}');
      }
    });

    _socket!.on('authentication_error', (data) {
      debugPrint('WebSocket: Authentication failed: $data');
      disconnect();
    });

    // Booking events
    _socket!.on('booking_status_changed', (data) {
      _handleBookingStatusChange(data);
    });

    _socket!.on('new_booking', (data) {
      _handleNewBooking(data);
    });

    _socket!.on('worker_assigned', (data) {
      _handleWorkerAssignment(data);
    });

    // Payment events
    _socket!.on('payment_required', (data) {
      _handlePaymentRequired(data);
    });

    _socket!.on('payment_completed', (data) {
      _handlePaymentCompleted(data);
    });

    // Notification events
    _socket!.on('new_notification', (data) {
      _handleNewNotification(data);
    });

    // Heartbeat
    _socket!.on('heartbeat_response', (data) {
      debugPrint('WebSocket: Heartbeat response received');
    });
  }

  // Handle booking status changes
  void _handleBookingStatusChange(dynamic data) {
    try {
      final statusUpdate =
          BookingStatusUpdate.fromJson(data as Map<String, dynamic>);
      debugPrint(
          'WebSocket: Booking status changed: ${statusUpdate.bookingId} -> ${statusUpdate.newStatus}');
      _bookingStatusController.add(statusUpdate);
    } catch (e) {
      debugPrint('WebSocket: Error handling booking status change: $e');
    }
  }

  // Handle new booking notifications
  void _handleNewBooking(dynamic data) {
    try {
      final bookingData = data['booking'] as Map<String, dynamic>;
      final booking = BookingModel.fromJson(bookingData);
      debugPrint('WebSocket: New booking received: ${booking.id}');
      _newBookingController.add(booking);
    } catch (e) {
      debugPrint('WebSocket: Error handling new booking: $e');
    }
  }

  // Handle worker assignment
  void _handleWorkerAssignment(dynamic data) {
    try {
      final assignment =
          WorkerAssignment.fromJson(data as Map<String, dynamic>);
      debugPrint(
          'WebSocket: Worker assigned: ${assignment.worker.name} -> ${assignment.bookingId}');
      _workerAssignmentController.add(assignment);
    } catch (e) {
      debugPrint('WebSocket: Error handling worker assignment: $e');
    }
  }

  // Handle payment required notification
  void _handlePaymentRequired(dynamic data) {
    try {
      final payment =
          PaymentNotification.fromJson(data as Map<String, dynamic>);
      debugPrint(
          'WebSocket: Payment required for booking: ${payment.bookingId}');
      _paymentController.add(payment);
    } catch (e) {
      debugPrint('WebSocket: Error handling payment required: $e');
    }
  }

  // Handle payment completion
  void _handlePaymentCompleted(dynamic data) {
    try {
      final payment =
          PaymentNotification.fromJson(data as Map<String, dynamic>);
      debugPrint(
          'WebSocket: Payment completed for booking: ${payment.bookingId}');
      _paymentController.add(payment);
    } catch (e) {
      debugPrint('WebSocket: Error handling payment completion: $e');
    }
  }

  // Handle new notifications
  void _handleNewNotification(dynamic data) {
    try {
      final notificationData = data['notification'] as Map<String, dynamic>;
      final notification = NotificationModel.fromJson(notificationData);
      debugPrint('WebSocket: New notification: ${notification.title}');
      _notificationController.add(notification);
    } catch (e) {
      debugPrint('WebSocket: Error handling notification: $e');
    }
  }

  void _handleUserBookingUpdate(dynamic data) {
    try {
      final updateData = data as Map<String, dynamic>;
      final type = updateData['type'] as String;
      final booking =
          BookingModel.fromJson(updateData['booking'] as Map<String, dynamic>);
      final message = updateData['message'] as String?;

      debugPrint(
          'WebSocket: User booking update - Type: $type, Booking: ${booking.id}');

      // Create a booking status update
      final statusUpdate = BookingStatusUpdate(
        bookingId: booking.id,
        newStatus: booking.status,
        previousStatus: '', // We don't have this info from the WebSocket event
        timestamp: DateTime.now(),
        booking: booking,
        message: message,
      );

      _bookingStatusController.add(statusUpdate);

      // Also handle specific update types
      switch (type) {
        case 'worker_assigned':
          if (booking.assignedEmployeeName != null) {
            final workerAssignment = WorkerAssignment(
              bookingId: booking.id,
              worker: Worker(
                id: booking.assignedEmployee ?? '',
                name: booking.assignedEmployeeName ?? '',
                phone: booking.assignedEmployeePhone ?? '',
              ),
              booking: booking,
              timestamp: DateTime.now(),
            );
            _workerAssignmentController.add(workerAssignment);
          }
          break;
        case 'service_completed':
        case 'payment_required':
          final amount = updateData['paymentAmount'] as double? ??
              booking.actualAmount ??
              booking.paymentAmount ??
              0.0;

          final paymentNotification = PaymentNotification(
            type: 'payment_required',
            bookingId: booking.id,
            amount: amount,
            booking: booking,
            timestamp: DateTime.now(),
          );
          _paymentController.add(paymentNotification);

          // Also create a notification model for the notification handler
          final notification = NotificationModel(
            id: 'payment_${booking.id}_${DateTime.now().millisecondsSinceEpoch}',
            title: '💳 Payment Required',
            message: message ??
                'Your service is complete. Please proceed with payment.',
            type: 'payment_required',
            recipient: 'user',
            relatedBookingId: booking.id,
            priority: 'high',
            isRead: false,
            actionRequired: true,
            actionUrl: '/payment',
            data: {
              'bookingId': booking.id,
              'actualAmount': amount,
              'paymentAmount': amount,
              'serviceType': booking.serviceType,
              'paymentRequired': true,
            },
            createdAt: DateTime.now(),
          );
          _notificationController.add(notification);
          break;
      }
    } catch (e) {
      debugPrint('WebSocket: Error handling user booking update: $e');
    }
  }

  // Subscribe to booking updates
  void subscribeToBookingUpdates(String bookingId) {
    if (_socket != null && _isConnected) {
      debugPrint('WebSocket: Subscribing to booking updates: $bookingId');
      _socket!.emit('subscribe_booking_updates', bookingId);
    }
  }

  // Subscribe to user-specific booking updates
  void subscribeToUserBookingUpdates(String userId) {
    if (_socket != null && _isConnected) {
      debugPrint('WebSocket: Subscribing to user booking updates: $userId');

      // Listen for user-specific booking updates
      _socket!.on('booking_update_$userId', (data) {
        debugPrint(
            'WebSocket: Received booking update for user $userId: $data');
        _handleUserBookingUpdate(data);
      });
    }
  }

  // Unsubscribe from booking updates
  void unsubscribeFromBookingUpdates(String bookingId) {
    if (_socket != null && _isConnected) {
      debugPrint('WebSocket: Unsubscribing from booking updates: $bookingId');
      _socket!.emit('unsubscribe_booking_updates', bookingId);
    }
  }

  // Start heartbeat to keep connection alive
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      if (_socket != null && _isConnected) {
        _socket!.emit('heartbeat');
      }
    });
  }

  // Stop heartbeat
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  // Schedule reconnection
  void _scheduleReconnect(String token, String userType, String? baseUrl) {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('WebSocket: Max reconnection attempts reached');
      _connectionController.add(ConnectionStatus.failed);
      return;
    }

    _reconnectAttempts++;
    debugPrint(
        'WebSocket: Scheduling reconnect attempt $_reconnectAttempts in ${_reconnectDelay.inSeconds}s');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () {
      connect(token: token, userType: userType, baseUrl: baseUrl);
    });
  }

  // Disconnect from WebSocket
  void disconnect() {
    debugPrint('WebSocket: Disconnecting');

    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();

    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }

    _isConnected = false;
    _isConnecting = false;
    _reconnectAttempts = 0;
    _connectionController.add(ConnectionStatus.disconnected);
    notifyListeners();
  }

  // Get connection statistics
  Map<String, dynamic> getConnectionStats() {
    return {
      'isConnected': _isConnected,
      'isConnecting': _isConnecting,
      'reconnectAttempts': _reconnectAttempts,
      'maxReconnectAttempts': _maxReconnectAttempts,
    };
  }

  @override
  void dispose() {
    disconnect();
    _bookingStatusController.close();
    _newBookingController.close();
    _workerAssignmentController.close();
    _paymentController.close();
    _notificationController.close();
    _connectionController.close();
    super.dispose();
  }
}

// Data models for WebSocket events
class BookingStatusUpdate {
  final String bookingId;
  final String newStatus;
  final String previousStatus;
  final DateTime timestamp;
  final BookingModel booking;
  final String? message;

  BookingStatusUpdate({
    required this.bookingId,
    required this.newStatus,
    required this.previousStatus,
    required this.timestamp,
    required this.booking,
    this.message,
  });

  factory BookingStatusUpdate.fromJson(Map<String, dynamic> json) {
    return BookingStatusUpdate(
      bookingId: json['bookingId'] ?? '',
      newStatus: json['newStatus'] ?? '',
      previousStatus: json['previousStatus'] ?? '',
      timestamp:
          DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      booking: BookingModel.fromJson(json['booking'] ?? {}),
    );
  }
}

class WorkerAssignment {
  final String bookingId;
  final Worker worker;
  final BookingModel booking;
  final DateTime timestamp;

  WorkerAssignment({
    required this.bookingId,
    required this.worker,
    required this.booking,
    required this.timestamp,
  });

  factory WorkerAssignment.fromJson(Map<String, dynamic> json) {
    return WorkerAssignment(
      bookingId: json['bookingId'] ?? '',
      worker: Worker.fromJson(json['worker'] ?? {}),
      booking: BookingModel.fromJson(json['booking'] ?? {}),
      timestamp:
          DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class Worker {
  final String id;
  final String name;
  final String phone;

  Worker({
    required this.id,
    required this.name,
    required this.phone,
  });

  factory Worker.fromJson(Map<String, dynamic> json) {
    return Worker(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}

class PaymentNotification {
  final String type;
  final String bookingId;
  final double amount;
  final String? transactionId;
  final BookingModel booking;
  final DateTime timestamp;

  PaymentNotification({
    required this.type,
    required this.bookingId,
    required this.amount,
    this.transactionId,
    required this.booking,
    required this.timestamp,
  });

  factory PaymentNotification.fromJson(Map<String, dynamic> json) {
    return PaymentNotification(
      type: json['type'] ?? '',
      bookingId: json['bookingId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      transactionId: json['transactionId'],
      booking: BookingModel.fromJson(json['booking'] ?? {}),
      timestamp:
          DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }
}

enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
  failed,
}
