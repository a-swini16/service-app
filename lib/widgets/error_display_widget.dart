import 'package:flutter/material.dart';
import '../services/error_handling_service.dart';

/// Widget for displaying errors to users with appropriate actions
class ErrorDisplayWidget extends StatelessWidget {
  final AppError error;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final bool showDetails;

  const ErrorDisplayWidget({
    Key? key,
    required this.error,
    this.onRetry,
    this.onDismiss,
    this.showDetails = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  _getErrorIcon(),
                  color: _getErrorColor(),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getErrorTitle(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: _getErrorColor(),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              error.message,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (showDetails && error.code.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Error Code: ${error.code}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
            if (showDetails) ...[
              const SizedBox(height: 8),
              Text(
                'Time: ${_formatTimestamp(error.timestamp)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onDismiss != null)
                  TextButton(
                    onPressed: onDismiss,
                    child: const Text('Dismiss'),
                  ),
                if (error.isRetryable && onRetry != null) ...[
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onRetry,
                    child: const Text('Retry'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getErrorIcon() {
    switch (error.type) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.authentication:
        return Icons.lock;
      case ErrorType.authorization:
        return Icons.block;
      case ErrorType.validation:
        return Icons.error_outline;
      case ErrorType.server:
        return Icons.dns;
      case ErrorType.notFound:
        return Icons.search_off;
      case ErrorType.conflict:
        return Icons.warning;
      case ErrorType.rateLimited:
        return Icons.speed;
      case ErrorType.parsing:
        return Icons.data_usage;
      case ErrorType.cancelled:
        return Icons.cancel;
      case ErrorType.unknown:
      default:
        return Icons.error;
    }
  }

  Color _getErrorColor() {
    switch (error.type) {
      case ErrorType.network:
        return Colors.orange;
      case ErrorType.authentication:
      case ErrorType.authorization:
        return Colors.red;
      case ErrorType.validation:
        return Colors.amber;
      case ErrorType.server:
        return Colors.red;
      case ErrorType.notFound:
        return Colors.blue;
      case ErrorType.conflict:
        return Colors.orange;
      case ErrorType.rateLimited:
        return Colors.purple;
      case ErrorType.parsing:
        return Colors.teal;
      case ErrorType.cancelled:
        return Colors.grey;
      case ErrorType.unknown:
      default:
        return Colors.red;
    }
  }

  String _getErrorTitle() {
    switch (error.type) {
      case ErrorType.network:
        return 'Connection Problem';
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

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}

/// Compact error banner widget
class ErrorBannerWidget extends StatelessWidget {
  final AppError error;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const ErrorBannerWidget({
    Key? key,
    required this.error,
    this.onRetry,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getErrorColor().withOpacity(0.1),
        border: Border.all(color: _getErrorColor().withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            _getErrorIcon(),
            color: _getErrorColor(),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error.message,
              style: TextStyle(
                color: _getErrorColor(),
                fontSize: 14,
              ),
            ),
          ),
          if (error.isRetryable && onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Retry',
                style: TextStyle(color: _getErrorColor()),
              ),
            ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: Icon(
                Icons.close,
                color: _getErrorColor(),
                size: 18,
              ),
            ),
        ],
      ),
    );
  }

  IconData _getErrorIcon() {
    switch (error.type) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.authentication:
        return Icons.lock;
      case ErrorType.authorization:
        return Icons.block;
      case ErrorType.validation:
        return Icons.error_outline;
      case ErrorType.server:
        return Icons.dns;
      case ErrorType.notFound:
        return Icons.search_off;
      case ErrorType.conflict:
        return Icons.warning;
      case ErrorType.rateLimited:
        return Icons.speed;
      case ErrorType.parsing:
        return Icons.data_usage;
      case ErrorType.cancelled:
        return Icons.cancel;
      case ErrorType.unknown:
      default:
        return Icons.error;
    }
  }

  Color _getErrorColor() {
    switch (error.type) {
      case ErrorType.network:
        return Colors.orange;
      case ErrorType.authentication:
      case ErrorType.authorization:
        return Colors.red;
      case ErrorType.validation:
        return Colors.amber;
      case ErrorType.server:
        return Colors.red;
      case ErrorType.notFound:
        return Colors.blue;
      case ErrorType.conflict:
        return Colors.orange;
      case ErrorType.rateLimited:
        return Colors.purple;
      case ErrorType.parsing:
        return Colors.teal;
      case ErrorType.cancelled:
        return Colors.grey;
      case ErrorType.unknown:
      default:
        return Colors.red;
    }
  }
}

/// Error list widget for displaying multiple errors
class ErrorListWidget extends StatelessWidget {
  final List<AppError> errors;
  final Function(AppError)? onRetry;
  final Function(AppError)? onDismiss;

  const ErrorListWidget({
    Key? key,
    required this.errors,
    this.onRetry,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (errors.isEmpty) {
      return const Center(
        child: Text('No errors to display'),
      );
    }

    return ListView.builder(
      itemCount: errors.length,
      itemBuilder: (context, index) {
        final error = errors[index];
        return ErrorDisplayWidget(
          error: error,
          showDetails: true,
          onRetry: onRetry != null ? () => onRetry!(error) : null,
          onDismiss: onDismiss != null ? () => onDismiss!(error) : null,
        );
      },
    );
  }
}