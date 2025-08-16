import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'error_logging_service.dart';

/// Centralized error handling service for the application
class ErrorHandlingService {
  static final ErrorHandlingService _instance = ErrorHandlingService._internal();
  factory ErrorHandlingService() => _instance;
  ErrorHandlingService._internal();

  final ErrorLoggingService _logger = ErrorLoggingService();

  /// Handle and process different types of errors
  Future<AppError> handleError(dynamic error, {String? context}) async {
    AppError appError;

    if (error is DioException) {
      appError = await _handleDioError(error);
    } else if (error is SocketException) {
      appError = _handleNetworkError(error);
    } else if (error is FormatException) {
      appError = _handleFormatError(error);
    } else if (error is AppError) {
      appError = error;
    } else {
      appError = _handleGenericError(error);
    }

    // Log the error
    await _logger.logError(appError, context: context);

    return appError;
  }

  /// Handle Dio HTTP errors
  Future<AppError> _handleDioError(DioException error) async {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AppError(
          type: ErrorType.network,
          code: 'TIMEOUT',
          message: 'Connection timeout. Please check your internet connection and try again.',
          isRetryable: true,
          originalError: error,
        );

      case DioExceptionType.connectionError:
        final isConnected = await _checkConnectivity();
        return AppError(
          type: ErrorType.network,
          code: 'CONNECTION_ERROR',
          message: isConnected 
            ? 'Unable to connect to server. Please try again later.'
            : 'No internet connection. Please check your network settings.',
          isRetryable: true,
          originalError: error,
        );

      case DioExceptionType.badResponse:
        return _handleHttpError(error);

      case DioExceptionType.cancel:
        return AppError(
          type: ErrorType.cancelled,
          code: 'REQUEST_CANCELLED',
          message: 'Request was cancelled.',
          isRetryable: false,
          originalError: error,
        );

      default:
        return AppError(
          type: ErrorType.unknown,
          code: 'UNKNOWN_NETWORK_ERROR',
          message: 'An unexpected network error occurred. Please try again.',
          isRetryable: true,
          originalError: error,
        );
    }
  }

  /// Handle HTTP response errors
  AppError _handleHttpError(DioException error) {
    final statusCode = error.response?.statusCode ?? 0;
    final responseData = error.response?.data;

    switch (statusCode) {
      case 400:
        return AppError(
          type: ErrorType.validation,
          code: 'BAD_REQUEST',
          message: _extractErrorMessage(responseData) ?? 'Invalid request. Please check your input.',
          isRetryable: false,
          originalError: error,
        );

      case 401:
        return AppError(
          type: ErrorType.authentication,
          code: 'UNAUTHORIZED',
          message: 'Your session has expired. Please log in again.',
          isRetryable: false,
          originalError: error,
        );

      case 403:
        return AppError(
          type: ErrorType.authorization,
          code: 'FORBIDDEN',
          message: 'You don\'t have permission to perform this action.',
          isRetryable: false,
          originalError: error,
        );

      case 404:
        return AppError(
          type: ErrorType.notFound,
          code: 'NOT_FOUND',
          message: 'The requested resource was not found.',
          isRetryable: false,
          originalError: error,
        );

      case 409:
        return AppError(
          type: ErrorType.conflict,
          code: 'CONFLICT',
          message: _extractErrorMessage(responseData) ?? 'A conflict occurred. Please try again.',
          isRetryable: true,
          originalError: error,
        );

      case 429:
        return AppError(
          type: ErrorType.rateLimited,
          code: 'RATE_LIMITED',
          message: 'Too many requests. Please wait a moment and try again.',
          isRetryable: true,
          originalError: error,
        );

      case 500:
      case 502:
      case 503:
      case 504:
        return AppError(
          type: ErrorType.server,
          code: 'SERVER_ERROR',
          message: 'Server is temporarily unavailable. Please try again later.',
          isRetryable: true,
          originalError: error,
        );

      default:
        return AppError(
          type: ErrorType.unknown,
          code: 'HTTP_ERROR',
          message: 'An unexpected error occurred. Please try again.',
          isRetryable: true,
          originalError: error,
        );
    }
  }

  /// Handle network connectivity errors
  AppError _handleNetworkError(SocketException error) {
    return AppError(
      type: ErrorType.network,
      code: 'NETWORK_ERROR',
      message: 'Network connection failed. Please check your internet connection.',
      isRetryable: true,
      originalError: error,
    );
  }

  /// Handle format/parsing errors
  AppError _handleFormatError(FormatException error) {
    return AppError(
      type: ErrorType.parsing,
      code: 'FORMAT_ERROR',
      message: 'Invalid data format received. Please try again.',
      isRetryable: true,
      originalError: error,
    );
  }

  /// Handle generic errors
  AppError _handleGenericError(dynamic error) {
    return AppError(
      type: ErrorType.unknown,
      code: 'GENERIC_ERROR',
      message: 'An unexpected error occurred. Please try again.',
      isRetryable: true,
      originalError: error,
    );
  }

  /// Extract error message from response data
  String? _extractErrorMessage(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      return responseData['message'] ?? responseData['error']?['message'];
    }
    return null;
  }

  /// Check network connectivity
  Future<bool> _checkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  /// Show error dialog to user
  void showErrorDialog(BuildContext context, AppError error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getErrorTitle(error.type)),
        content: Text(error.message),
        actions: [
          if (error.isRetryable)
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Retry'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show error snackbar
  void showErrorSnackbar(BuildContext context, AppError error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.message),
        backgroundColor: Colors.red,
        action: error.isRetryable
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () {
                  // Retry logic will be handled by the calling widget
                },
              )
            : null,
      ),
    );
  }

  /// Get appropriate error title based on error type
  String _getErrorTitle(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return 'Connection Error';
      case ErrorType.authentication:
        return 'Authentication Required';
      case ErrorType.authorization:
        return 'Access Denied';
      case ErrorType.validation:
        return 'Invalid Input';
      case ErrorType.server:
        return 'Server Error';
      case ErrorType.notFound:
        return 'Not Found';
      case ErrorType.conflict:
        return 'Conflict';
      case ErrorType.rateLimited:
        return 'Rate Limited';
      case ErrorType.parsing:
        return 'Data Error';
      case ErrorType.cancelled:
        return 'Cancelled';
      case ErrorType.unknown:
      default:
        return 'Error';
    }
  }
}

/// Custom application error class
class AppError {
  final ErrorType type;
  final String code;
  final String message;
  final bool isRetryable;
  final dynamic originalError;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  AppError({
    required this.type,
    required this.code,
    required this.message,
    required this.isRetryable,
    this.originalError,
    this.metadata,
  }) : timestamp = DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'code': code,
      'message': message,
      'isRetryable': isRetryable,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  @override
  String toString() {
    return 'AppError(type: $type, code: $code, message: $message)';
  }
}

/// Error types for categorization
enum ErrorType {
  network,
  authentication,
  authorization,
  validation,
  server,
  notFound,
  conflict,
  rateLimited,
  parsing,
  cancelled,
  unknown,
}