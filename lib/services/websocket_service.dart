import 'dart:async';
import 'package:om_enterprises/constants/app_constants.dart';
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

  // Helper method to properly clean up existing socket
  Future<void> _cleanupExistingSocket() async {
    if (_socket != null) {
      debugPrint('WebSocket: Cleaning up existing socket');
      
      // Cancel any existing timers
      _heartbeatTimer?.cancel();
      _reconnectTimer?.cancel();
      
      try {
        _socket!.disconnect();
        _socket!.dispose();
      } catch (e) {
        debugPrint('WebSocket: Error during socket cleanup: $e');
      }
      
      _socket = null;
      
      // Small delay to ensure cleanup is complete
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  // Initialize WebSocket connection with improved reliability
  Future<void> connect({
    required String token,
    required String userType,
    String? baseUrl,
  }) async {
    // Check if already connected or connecting
    if (_isConnected) {
      debugPrint('WebSocket: Already connected');
      return;
    }
    
    if (_isConnecting) {
      debugPrint('WebSocket: Connection already in progress');
      return;
    }

    _isConnecting = true;
    _connectionController.add(ConnectionStatus.connecting);
    notifyListeners();

    try {
      // Properly clean up any existing socket
      await _cleanupExistingSocket();
      
      final serverUrl = baseUrl ?? AppConstants.socketUrl;
      debugPrint('WebSocket: Connecting to $serverUrl');

      _socket = io.io(
          serverUrl,
          io.OptionBuilder()
              .setTransports(['websocket', 'polling']) // Try WebSocket first, fallback to polling
              .disableAutoConnect() // We'll manually connect
              .enableForceNew() // Force a new connection
              .enableReconnection() 
              .setReconnectionAttempts(10) // Increased from 5
              .setReconnectionDelay(3000)
              .setReconnectionDelayMax(10000) // Cap at 10 seconds
              .setTimeout(20000) // Increase timeout to 20 seconds
              .setQuery({'token': token, 'userType': userType}) // Add auth params to URL
              .build());

      _setupEventHandlers();

      // Authenticate after connection
      _socket!.onConnect((_) {
        debugPrint('WebSocket: Connected to server');
        _authenticate(token, userType);
      });

      _socket!.connect();
      
      // Set a connection timeout
      Timer(const Duration(seconds: 10), () {
        if (_isConnecting && !_isConnected) {
          debugPrint('WebSocket: Connection timeout after 10 seconds');
          _isConnecting = false;
          _connectionController.add(ConnectionStatus.error);
          notifyListeners();
          
          // Try to reconnect
          _scheduleReconnect(token, userType, baseUrl);
        }
      });
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

  // Start heartbeat to keep connection alive and detect disconnections
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    
    // Track heartbeat responses
    int missedHeartbeats = 0;
    DateTime? lastHeartbeatTime;
    String? lastToken;
    String? lastUserType;
    
    _socket!.on('heartbeat_response', (data) {
      missedHeartbeats = 0;
      lastHeartbeatTime = DateTime.now();
      debugPrint('WebSocket: Heartbeat response received');
    });
    
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      if (_socket != null && _isConnected) {
        // If we didn't get a response to the previous heartbeat, increment missed count
        if (missedHeartbeats > 0) {
          debugPrint('WebSocket: Heartbeat failed, missed count: $missedHeartbeats');
        }
        
        // If we've missed 2 consecutive heartbeats, force reconnect
        if (missedHeartbeats >= 2) {
          debugPrint('WebSocket: Multiple heartbeats missed, forcing reconnection');
          
          // Store authentication info before disconnecting
          try {
            final query = _socket!.opts?['query'] as Map<String, dynamic>?;
            if (query != null) {
              lastToken = query['token'] as String?;
              lastUserType = query['userType'] as String?;
            }
          } catch (e) {
            debugPrint('WebSocket: Error retrieving auth info: $e');
          }
          
          _socket!.disconnect();
          
          // Try to reconnect immediately with stored auth info
          if (lastToken != null && lastUserType != null) {
            Timer(const Duration(milliseconds: 500), () {
              debugPrint('WebSocket: Attempting reconnect with stored auth info');
              connect(token: lastToken!, userType: lastUserType!);
            });
          }
          return;
        }
        
        // Increment missed count and send heartbeat
        missedHeartbeats++;
        _socket!.emit('heartbeat');
      }
    });
  }

  // Stop heartbeat
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  // Schedule reconnection with improved exponential backoff and jitter
  void _scheduleReconnect(String token, String userType, String? baseUrl) {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('WebSocket: Max reconnection attempts reached');
      _connectionController.add(ConnectionStatus.failed);
      return;
    }

    _reconnectAttempts++;
    _isConnecting = true;
    _connectionController.add(ConnectionStatus.connecting);
    notifyListeners();
    
    // Use exponential backoff with jitter for reconnection
    final baseDelay = _reconnectDelay.inMilliseconds;
    final exponentialDelay = baseDelay * (1 << (_reconnectAttempts - 1)); // 2^(attempts-1) * baseDelay
    final maxDelay = 30000; // Cap at 30 seconds
    
    // Add 0-30% random jitter to prevent thundering herd problem
    final jitterPercent = (DateTime.now().millisecondsSinceEpoch % 30) / 100; // 0.00 to 0.29
    final jitter = (exponentialDelay * jitterPercent).toInt();
    
    final actualDelay = Duration(milliseconds: (exponentialDelay + jitter).clamp(baseDelay, maxDelay));
    
    debugPrint(
        'WebSocket: Scheduling reconnect attempt $_reconnectAttempts in ${actualDelay.inSeconds}s (with ${(jitterPercent * 100).toStringAsFixed(1)}% jitter)');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(actualDelay, () {
      try {
        connect(token: token, userType: userType, baseUrl: baseUrl);
      } catch (e) {
        debugPrint('WebSocket: Error during reconnection attempt: $e');
        // If reconnection fails, schedule another attempt
        _scheduleReconnect(token, userType, baseUrl);
      }
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
