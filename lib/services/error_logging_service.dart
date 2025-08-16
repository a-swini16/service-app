import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'error_handling_service.dart';

/// Service for logging errors and sending them to monitoring systems
class ErrorLoggingService {
  static final ErrorLoggingService _instance = ErrorLoggingService._internal();
  factory ErrorLoggingService() => _instance;
  ErrorLoggingService._internal();

  static const String _logFileName = 'error_logs.json';
  static const int _maxLogEntries = 1000;
  
  List<ErrorLogEntry> _logEntries = [];
  bool _initialized = false;

  /// Initialize the logging service
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      await _loadExistingLogs();
      _initialized = true;
    } catch (e) {
      debugPrint('Failed to initialize error logging service: $e');
    }
  }

  /// Log an error with context information
  Future<void> logError(AppError error, {String? context}) async {
    try {
      final deviceInfo = await _getDeviceInfo();
      final appInfo = await _getAppInfo();
      
      final logEntry = ErrorLogEntry(
        error: error,
        context: context,
        deviceInfo: deviceInfo,
        appInfo: appInfo,
        stackTrace: _getCurrentStackTrace(),
      );

      _logEntries.add(logEntry);
      
      // Keep only the most recent entries
      if (_logEntries.length > _maxLogEntries) {
        _logEntries = _logEntries.sublist(_logEntries.length - _maxLogEntries);
      }

      // Save to local storage
      await _saveLogsToFile();
      
      // Send to remote monitoring (if configured)
      await _sendToRemoteMonitoring(logEntry);
      
      // Print to console in debug mode
      if (kDebugMode) {
        debugPrint('ERROR LOGGED: ${error.code} - ${error.message}');
        if (context != null) {
          debugPrint('CONTEXT: $context');
        }
      }
    } catch (e) {
      debugPrint('Failed to log error: $e');
    }
  }

  /// Log a custom event or information
  Future<void> logEvent(String event, Map<String, dynamic>? data) async {
    try {
      final deviceInfo = await _getDeviceInfo();
      final appInfo = await _getAppInfo();
      
      final logEntry = ErrorLogEntry(
        error: AppError(
          type: ErrorType.unknown,
          code: 'EVENT',
          message: event,
          isRetryable: false,
        ),
        context: 'Custom Event',
        deviceInfo: deviceInfo,
        appInfo: appInfo,
        customData: data,
      );

      _logEntries.add(logEntry);
      await _saveLogsToFile();
      
      if (kDebugMode) {
        debugPrint('EVENT LOGGED: $event');
        if (data != null) {
          debugPrint('DATA: ${jsonEncode(data)}');
        }
      }
    } catch (e) {
      debugPrint('Failed to log event: $e');
    }
  }

  /// Get recent error logs
  List<ErrorLogEntry> getRecentLogs({int? limit}) {
    final logs = List<ErrorLogEntry>.from(_logEntries);
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    if (limit != null && logs.length > limit) {
      return logs.sublist(0, limit);
    }
    
    return logs;
  }

  /// Get error statistics
  Map<String, dynamic> getErrorStatistics() {
    final now = DateTime.now();
    final last24Hours = now.subtract(const Duration(hours: 24));
    final last7Days = now.subtract(const Duration(days: 7));
    
    final recent24h = _logEntries.where((log) => log.timestamp.isAfter(last24Hours)).toList();
    final recent7d = _logEntries.where((log) => log.timestamp.isAfter(last7Days)).toList();
    
    final errorTypeCount = <String, int>{};
    for (final log in recent24h) {
      final type = log.error.type.toString();
      errorTypeCount[type] = (errorTypeCount[type] ?? 0) + 1;
    }
    
    return {
      'totalErrors': _logEntries.length,
      'errorsLast24h': recent24h.length,
      'errorsLast7d': recent7d.length,
      'errorTypeBreakdown': errorTypeCount,
      'mostCommonError': errorTypeCount.entries
          .fold<MapEntry<String, int>?>(null, (prev, curr) => 
              prev == null || curr.value > prev.value ? curr : prev)
          ?.key,
    };
  }

  /// Clear old logs
  Future<void> clearOldLogs({Duration? olderThan}) async {
    final cutoff = DateTime.now().subtract(olderThan ?? const Duration(days: 30));
    _logEntries.removeWhere((log) => log.timestamp.isBefore(cutoff));
    await _saveLogsToFile();
  }

  /// Export logs for debugging
  Future<String> exportLogs() async {
    final logs = _logEntries.map((log) => log.toJson()).toList();
    return jsonEncode({
      'exportedAt': DateTime.now().toIso8601String(),
      'totalLogs': logs.length,
      'logs': logs,
    });
  }

  /// Load existing logs from file
  Future<void> _loadExistingLogs() async {
    try {
      final file = await _getLogFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content) as List<dynamic>;
        _logEntries = data.map((json) => ErrorLogEntry.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Failed to load existing logs: $e');
      _logEntries = [];
    }
  }

  /// Save logs to file
  Future<void> _saveLogsToFile() async {
    try {
      final file = await _getLogFile();
      final data = _logEntries.map((log) => log.toJson()).toList();
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint('Failed to save logs to file: $e');
    }
  }

  /// Get log file
  Future<File> _getLogFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_logFileName');
  }

  /// Get device information
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return {
          'platform': 'Android',
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'version': androidInfo.version.release,
          'sdkInt': androidInfo.version.sdkInt,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return {
          'platform': 'iOS',
          'model': iosInfo.model,
          'name': iosInfo.name,
          'systemVersion': iosInfo.systemVersion,
        };
      }
    } catch (e) {
      debugPrint('Failed to get device info: $e');
    }
    
    return {
      'platform': Platform.operatingSystem,
      'version': Platform.operatingSystemVersion,
    };
  }

  /// Get app information
  Future<Map<String, dynamic>> _getAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return {
        'appName': packageInfo.appName,
        'packageName': packageInfo.packageName,
        'version': packageInfo.version,
        'buildNumber': packageInfo.buildNumber,
      };
    } catch (e) {
      debugPrint('Failed to get app info: $e');
      return {};
    }
  }

  /// Get current stack trace
  String _getCurrentStackTrace() {
    try {
      throw Exception('Stack trace');
    } catch (e, stackTrace) {
      return stackTrace.toString();
    }
  }

  /// Send error to remote monitoring service
  Future<void> _sendToRemoteMonitoring(ErrorLogEntry logEntry) async {
    // TODO: Implement remote monitoring integration
    // This could integrate with services like Sentry, Crashlytics, or custom analytics
    
    if (kDebugMode) {
      debugPrint('Would send to remote monitoring: ${logEntry.error.code}');
    }
  }
}

/// Error log entry model
class ErrorLogEntry {
  final AppError error;
  final String? context;
  final Map<String, dynamic> deviceInfo;
  final Map<String, dynamic> appInfo;
  final String? stackTrace;
  final Map<String, dynamic>? customData;
  final DateTime timestamp;

  ErrorLogEntry({
    required this.error,
    this.context,
    required this.deviceInfo,
    required this.appInfo,
    this.stackTrace,
    this.customData,
  }) : timestamp = DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'error': error.toJson(),
      'context': context,
      'deviceInfo': deviceInfo,
      'appInfo': appInfo,
      'stackTrace': stackTrace,
      'customData': customData,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ErrorLogEntry.fromJson(Map<String, dynamic> json) {
    return ErrorLogEntry(
      error: AppError(
        type: ErrorType.values.firstWhere(
          (e) => e.toString() == json['error']['type'],
          orElse: () => ErrorType.unknown,
        ),
        code: json['error']['code'],
        message: json['error']['message'],
        isRetryable: json['error']['isRetryable'],
        metadata: json['error']['metadata'],
      ),
      context: json['context'],
      deviceInfo: Map<String, dynamic>.from(json['deviceInfo'] ?? {}),
      appInfo: Map<String, dynamic>.from(json['appInfo'] ?? {}),
      stackTrace: json['stackTrace'],
      customData: json['customData'] != null 
          ? Map<String, dynamic>.from(json['customData'])
          : null,
    );
  }
}