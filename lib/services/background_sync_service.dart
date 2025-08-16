import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'data_sync_service.dart';
import 'local_database_service.dart';

class BackgroundSyncService {
  static const String _isolateName = 'background_sync_isolate';
  static const MethodChannel _channel = MethodChannel('om_enterprises/background_sync');
  
  static final BackgroundSyncService _instance = BackgroundSyncService._internal();
  factory BackgroundSyncService() => _instance;
  BackgroundSyncService._internal();

  Timer? _periodicSyncTimer;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isInitialized = false;
  bool _isSyncInProgress = false;

  // Configuration
  static const Duration periodicSyncInterval = Duration(minutes: 15);
  static const Duration retryInterval = Duration(minutes: 5);
  static const int maxRetryAttempts = 3;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Register background sync isolate
      await _registerBackgroundIsolate();
      
      // Start periodic sync
      _startPeriodicSync();
      
      // Listen to connectivity changes
      _listenToConnectivityChanges();
      
      // Setup platform channel for background tasks
      _setupPlatformChannel();
      
      _isInitialized = true;
      debugPrint('BackgroundSyncService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize BackgroundSyncService: $e');
    }
  }

  Future<void> _registerBackgroundIsolate() async {
    final receivePort = ReceivePort();
    
    // Register the isolate with a name so it can be found later
    IsolateNameServer.removePortNameMapping(_isolateName);
    IsolateNameServer.registerPortWithName(receivePort.sendPort, _isolateName);
    
    // Listen for messages from the isolate
    receivePort.listen((dynamic data) {
      _handleIsolateMessage(data);
    });
  }

  void _handleIsolateMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      switch (data['type']) {
        case 'sync_completed':
          _isSyncInProgress = false;
          debugPrint('Background sync completed: ${data['result']}');
          break;
        case 'sync_failed':
          _isSyncInProgress = false;
          debugPrint('Background sync failed: ${data['error']}');
          break;
        case 'sync_started':
          _isSyncInProgress = true;
          debugPrint('Background sync started');
          break;
      }
    }
  }

  void _startPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = Timer.periodic(periodicSyncInterval, (timer) {
      if (!_isSyncInProgress) {
        _triggerBackgroundSync();
      }
    });
  }

  void _listenToConnectivityChanges() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none && !_isSyncInProgress) {
        // Connection restored, trigger immediate sync
        Future.delayed(const Duration(seconds: 5), () {
          _triggerBackgroundSync();
        });
      }
    });
  }

  void _setupPlatformChannel() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'performBackgroundSync':
          return await _performBackgroundSync();
        case 'getSyncStatus':
          return _getSyncStatus();
        default:
          throw PlatformException(
            code: 'UNIMPLEMENTED',
            message: 'Method ${call.method} not implemented',
          );
      }
    });
  }

  Future<void> _triggerBackgroundSync() async {
    if (_isSyncInProgress) return;

    try {
      // Try to run sync in background isolate
      await _runSyncInIsolate();
    } catch (e) {
      debugPrint('Failed to trigger background sync: $e');
      // Fallback to main thread sync
      await _performBackgroundSync();
    }
  }

  Future<void> _runSyncInIsolate() async {
    final sendPort = IsolateNameServer.lookupPortByName(_isolateName);
    if (sendPort != null) {
      // Send sync command to isolate
      sendPort.send({
        'command': 'sync',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } else {
      // Isolate not available, create new one
      await Isolate.spawn(_backgroundSyncIsolateEntryPoint, null);
    }
  }

  static void _backgroundSyncIsolateEntryPoint(dynamic message) async {
    // This runs in a separate isolate
    final receivePort = ReceivePort();
    final sendPort = IsolateNameServer.lookupPortByName(_isolateName);
    
    if (sendPort != null) {
      sendPort.send({'type': 'sync_started'});
    }

    try {
      // Initialize services in isolate
      final localDb = LocalDatabaseService();
      final syncService = DataSyncService();
      
      // Perform sync
      final result = await syncService.syncData();
      
      if (sendPort != null) {
        sendPort.send({
          'type': 'sync_completed',
          'result': {
            'success': result.success,
            'synced_items': result.syncedItems,
            'failed_items': result.failedItems,
          }
        });
      }
    } catch (e) {
      if (sendPort != null) {
        sendPort.send({
          'type': 'sync_failed',
          'error': e.toString(),
        });
      }
    }
  }

  Future<Map<String, dynamic>> _performBackgroundSync() async {
    if (_isSyncInProgress) {
      return {'status': 'already_in_progress'};
    }

    _isSyncInProgress = true;
    
    try {
      final syncService = DataSyncService();
      final result = await syncService.syncData();
      
      return {
        'status': 'completed',
        'success': result.success,
        'synced_items': result.syncedItems,
        'failed_items': result.failedItems,
        'error': result.error,
      };
    } catch (e) {
      return {
        'status': 'failed',
        'error': e.toString(),
      };
    } finally {
      _isSyncInProgress = false;
    }
  }

  Map<String, dynamic> _getSyncStatus() {
    return {
      'is_sync_in_progress': _isSyncInProgress,
      'is_initialized': _isInitialized,
      'periodic_sync_interval_minutes': periodicSyncInterval.inMinutes,
    };
  }

  // Public methods
  Future<void> triggerImmediateSync() async {
    await _triggerBackgroundSync();
  }

  Future<void> scheduleSync({Duration? delay}) async {
    final actualDelay = delay ?? const Duration(seconds: 30);
    Timer(actualDelay, () {
      _triggerBackgroundSync();
    });
  }

  void pauseBackgroundSync() {
    _periodicSyncTimer?.cancel();
    _connectivitySubscription?.cancel();
  }

  void resumeBackgroundSync() {
    if (_isInitialized) {
      _startPeriodicSync();
      _listenToConnectivityChanges();
    }
  }

  bool get isSyncInProgress => _isSyncInProgress;
  bool get isInitialized => _isInitialized;

  void dispose() {
    _periodicSyncTimer?.cancel();
    _connectivitySubscription?.cancel();
    IsolateNameServer.removePortNameMapping(_isolateName);
    _isInitialized = false;
  }
}

// Helper class for managing sync operations
class SyncOperation {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final int retryCount;
  final DateTime? lastRetryAt;

  SyncOperation({
    required this.id,
    required this.type,
    required this.data,
    required this.createdAt,
    this.retryCount = 0,
    this.lastRetryAt,
  });

  factory SyncOperation.fromJson(Map<String, dynamic> json) {
    return SyncOperation(
      id: json['id'],
      type: json['type'],
      data: json['data'],
      createdAt: DateTime.parse(json['created_at']),
      retryCount: json['retry_count'] ?? 0,
      lastRetryAt: json['last_retry_at'] != null 
          ? DateTime.parse(json['last_retry_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'data': data,
      'created_at': createdAt.toIso8601String(),
      'retry_count': retryCount,
      'last_retry_at': lastRetryAt?.toIso8601String(),
    };
  }

  SyncOperation copyWith({
    String? id,
    String? type,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    int? retryCount,
    DateTime? lastRetryAt,
  }) {
    return SyncOperation(
      id: id ?? this.id,
      type: type ?? this.type,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      lastRetryAt: lastRetryAt ?? this.lastRetryAt,
    );
  }
}

// Sync queue manager
class SyncQueueManager {
  final LocalDatabaseService _localDb = LocalDatabaseService();
  
  Future<void> addOperation(SyncOperation operation) async {
    await _localDb.database.then((db) => db.insert('sync_queue', {
      'id': operation.id,
      'table_name': operation.type,
      'record_id': operation.id,
      'operation': 'SYNC',
      'data': operation.data.toString(),
      'created_at': operation.createdAt.toIso8601String(),
      'retry_count': operation.retryCount,
      'last_retry_at': operation.lastRetryAt?.toIso8601String(),
    }));
  }

  Future<List<SyncOperation>> getPendingOperations() async {
    final db = await _localDb.database;
    final maps = await db.query('sync_queue', orderBy: 'created_at ASC');
    
    return maps.map((map) => SyncOperation(
      id: map['record_id'] as String,
      type: map['table_name'] as String,
      data: {'raw': map['data']},
      createdAt: DateTime.parse(map['created_at'] as String),
      retryCount: map['retry_count'] as int? ?? 0,
      lastRetryAt: map['last_retry_at'] != null 
          ? DateTime.parse(map['last_retry_at'] as String)
          : null,
    )).toList();
  }

  Future<void> removeOperation(String id) async {
    final db = await _localDb.database;
    await db.delete('sync_queue', where: 'record_id = ?', whereArgs: [id]);
  }

  Future<void> incrementRetryCount(String id) async {
    final db = await _localDb.database;
    await db.update(
      'sync_queue',
      {
        'retry_count': 'retry_count + 1',
        'last_retry_at': DateTime.now().toIso8601String(),
      },
      where: 'record_id = ?',
      whereArgs: [id],
    );
  }
}