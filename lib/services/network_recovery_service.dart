import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'error_handling_service.dart';
import 'error_logging_service.dart';

/// Service for handling network failures and implementing recovery mechanisms
class NetworkRecoveryService {
  static final NetworkRecoveryService _instance = NetworkRecoveryService._internal();
  factory NetworkRecoveryService() => _instance;
  NetworkRecoveryService._internal();

  final ErrorLoggingService _logger = ErrorLoggingService();
  final Connectivity _connectivity = Connectivity();
  
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  final StreamController<bool> _connectionStatusController = StreamController<bool>.broadcast();
  
  bool _isConnected = true;
  final List<PendingRequest> _pendingRequests = [];
  Timer? _retryTimer;

  /// Stream of connection status changes
  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  /// Current connection status
  bool get isConnected => _isConnected;

  /// Initialize the network recovery service
  Future<void> initialize() async {
    // Check initial connectivity
    final result = await _connectivity.checkConnectivity();
    _isConnected = result != ConnectivityResult.none;
    
    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );
    
    await _logger.logEvent('NetworkRecoveryService initialized', {
      'initialConnection': _isConnected,
    });
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectionStatusController.close();
    _retryTimer?.cancel();
  }

  /// Execute a request with automatic retry and recovery
  Future<T> executeWithRecovery<T>(
    Future<T> Function() request, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
    double backoffMultiplier = 2.0,
    String? requestId,
  }) async {
    int attempts = 0;
    Duration delay = initialDelay;
    
    while (attempts <= maxRetries) {
      try {
        // Check connectivity before attempting request
        if (!_isConnected) {
          await _waitForConnection();
        }
        
        final result = await request();
        
        // Log successful recovery if this was a retry
        if (attempts > 0) {
          await _logger.logEvent('Request recovered successfully', {
            'requestId': requestId,
            'attempts': attempts + 1,
          });
        }
        
        return result;
      } catch (error) {
        attempts++;
        
        final appError = await ErrorHandlingService().handleError(
          error,
          context: 'NetworkRecovery - Attempt $attempts',
        );
        
        // Don't retry for non-retryable errors
        if (!appError.isRetryable || attempts > maxRetries) {
          await _logger.logError(appError, context: 'Max retries exceeded');
          rethrow;
        }
        
        // Log retry attempt
        await _logger.logEvent('Retrying request', {
          'requestId': requestId,
          'attempt': attempts,
          'delay': delay.inMilliseconds,
          'error': appError.code,
        });
        
        // Wait before retry with exponential backoff
        await Future.delayed(delay);
        delay = Duration(
          milliseconds: (delay.inMilliseconds * backoffMultiplier).round(),
        );
      }
    }
    
    throw Exception('Max retries exceeded');
  }

  /// Queue a request for later execution when connection is restored
  void queueRequest(PendingRequest request) {
    _pendingRequests.add(request);
    
    _logger.logEvent('Request queued for retry', {
      'requestId': request.id,
      'queueSize': _pendingRequests.length,
    });
  }

  /// Remove a request from the queue
  void removeQueuedRequest(String requestId) {
    _pendingRequests.removeWhere((request) => request.id == requestId);
  }

  /// Get queued requests count
  int get queuedRequestsCount => _pendingRequests.length;

  /// Handle connectivity changes
  void _onConnectivityChanged(ConnectivityResult result) {
    final wasConnected = _isConnected;
    _isConnected = result != ConnectivityResult.none;
    
    _connectionStatusController.add(_isConnected);
    
    _logger.logEvent('Connectivity changed', {
      'wasConnected': wasConnected,
      'isConnected': _isConnected,
      'result': result.toString(),
    });
    
    if (!wasConnected && _isConnected) {
      // Connection restored - process pending requests
      _processPendingRequests();
    }
  }

  /// Wait for connection to be restored
  Future<void> _waitForConnection({Duration timeout = const Duration(minutes: 5)}) async {
    if (_isConnected) return;
    
    final completer = Completer<void>();
    late StreamSubscription subscription;
    
    subscription = connectionStatus.listen((isConnected) {
      if (isConnected) {
        subscription.cancel();
        completer.complete();
      }
    });
    
    // Set timeout
    Timer(timeout, () {
      if (!completer.isCompleted) {
        subscription.cancel();
        completer.completeError(
          TimeoutException('Connection timeout', timeout),
        );
      }
    });
    
    return completer.future;
  }

  /// Process pending requests when connection is restored
  Future<void> _processPendingRequests() async {
    if (_pendingRequests.isEmpty) return;
    
    await _logger.logEvent('Processing pending requests', {
      'count': _pendingRequests.length,
    });
    
    final requests = List<PendingRequest>.from(_pendingRequests);
    _pendingRequests.clear();
    
    for (final request in requests) {
      try {
        await request.execute();
        
        await _logger.logEvent('Pending request executed successfully', {
          'requestId': request.id,
        });
      } catch (error) {
        final appError = await ErrorHandlingService().handleError(
          error,
          context: 'Processing pending request: ${request.id}',
        );
        
        // Re-queue if retryable
        if (appError.isRetryable && request.retryCount < request.maxRetries) {
          request.retryCount++;
          _pendingRequests.add(request);
        } else {
          await _logger.logError(appError, context: 'Failed to process pending request');
        }
      }
    }
  }

  /// Create a Dio interceptor for automatic retry
  Interceptor createRetryInterceptor({
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
  }) {
    return InterceptorsWrapper(
      onError: (error, handler) async {
        if (_shouldRetry(error) && error.requestOptions.extra['retryCount'] == null) {
          error.requestOptions.extra['retryCount'] = 0;
        }
        
        final retryCount = error.requestOptions.extra['retryCount'] as int? ?? 0;
        
        if (_shouldRetry(error) && retryCount < maxRetries) {
          error.requestOptions.extra['retryCount'] = retryCount + 1;
          
          final delay = Duration(
            milliseconds: (initialDelay.inMilliseconds * pow(2, retryCount)).round(),
          );
          
          await Future.delayed(delay);
          
          try {
            final response = await Dio().fetch(error.requestOptions);
            handler.resolve(response);
          } catch (e) {
            handler.next(DioException(
              requestOptions: error.requestOptions,
              error: e,
            ));
          }
        } else {
          handler.next(error);
        }
      },
    );
  }

  /// Check if an error should trigger a retry
  bool _shouldRetry(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        return statusCode != null && (statusCode >= 500 || statusCode == 429);
      default:
        return false;
    }
  }
}

/// Represents a request that can be queued and retried
class PendingRequest {
  final String id;
  final Future<void> Function() execute;
  final int maxRetries;
  int retryCount;
  final DateTime createdAt;

  PendingRequest({
    required this.id,
    required this.execute,
    this.maxRetries = 3,
    this.retryCount = 0,
  }) : createdAt = DateTime.now();

  bool get hasExpired {
    const maxAge = Duration(hours: 1);
    return DateTime.now().difference(createdAt) > maxAge;
  }
}

/// Exception thrown when waiting for connection times out
class TimeoutException implements Exception {
  final String message;
  final Duration timeout;

  TimeoutException(this.message, this.timeout);

  @override
  String toString() => 'TimeoutException: $message (${timeout.inSeconds}s)';
}