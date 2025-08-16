import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/booking_model.dart';
import '../models/notification_model.dart';

class LocalDatabaseService {
  static final LocalDatabaseService _instance = LocalDatabaseService._internal();
  factory LocalDatabaseService() => _instance;
  LocalDatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'om_enterprises_local.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create bookings table
    await db.execute('''
      CREATE TABLE bookings (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        service_type TEXT NOT NULL,
        customer_name TEXT NOT NULL,
        customer_phone TEXT NOT NULL,
        customer_address TEXT NOT NULL,
        description TEXT,
        preferred_date TEXT,
        preferred_time TEXT,
        status TEXT NOT NULL,
        status_history TEXT,
        assigned_employee TEXT,
        assigned_date TEXT,
        accepted_date TEXT,
        rejected_date TEXT,
        started_date TEXT,
        completed_date TEXT,
        payment_status TEXT,
        payment_method TEXT,
        payment_amount REAL,
        actual_amount REAL,
        payment_transaction_id TEXT,
        admin_notes TEXT,
        worker_notes TEXT,
        rejection_reason TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0,
        sync_version INTEGER DEFAULT 1,
        last_sync_at TEXT
      )
    ''');

    // Create notifications table
    await db.execute('''
      CREATE TABLE notifications (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        type TEXT NOT NULL,
        recipient TEXT NOT NULL,
        related_booking TEXT,
        related_user TEXT,
        related_employee TEXT,
        is_read INTEGER DEFAULT 0,
        read_at TEXT,
        priority TEXT DEFAULT 'medium',
        delivery_method TEXT DEFAULT 'both',
        delivery_status TEXT DEFAULT 'pending',
        data TEXT,
        action_required INTEGER DEFAULT 0,
        action_url TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0,
        sync_version INTEGER DEFAULT 1,
        last_sync_at TEXT
      )
    ''');

    // Create sync_queue table for tracking pending changes
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        data TEXT,
        created_at TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0,
        last_retry_at TEXT
      )
    ''');

    // Create sync_metadata table for tracking sync state
    await db.execute('''
      CREATE TABLE sync_metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_bookings_user_id ON bookings(user_id)');
    await db.execute('CREATE INDEX idx_bookings_status ON bookings(status)');
    await db.execute('CREATE INDEX idx_bookings_sync ON bookings(is_synced)');
    await db.execute('CREATE INDEX idx_notifications_recipient ON notifications(recipient)');
    await db.execute('CREATE INDEX idx_notifications_sync ON notifications(is_synced)');
    await db.execute('CREATE INDEX idx_sync_queue_table ON sync_queue(table_name)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database schema upgrades
    if (oldVersion < newVersion) {
      // Add migration logic here when needed
    }
  }

  // Booking operations
  Future<int> insertBooking(BookingModel booking) async {
    final db = await database;
    final bookingMap = booking.toJson();
    bookingMap['status_history'] = jsonEncode(booking.statusHistory.map((e) => {
      'status': e.status,
      'timestamp': e.timestamp.toIso8601String(),
      'updatedBy': e.updatedBy,
      'notes': e.notes,
    }).toList());
    bookingMap['is_synced'] = 0;
    bookingMap['sync_version'] = 1;
    bookingMap['last_sync_at'] = null;
    
    await _addToSyncQueue('bookings', booking.id, 'INSERT', jsonEncode(bookingMap));
    return await db.insert('bookings', bookingMap);
  }

  Future<int> updateBooking(BookingModel booking) async {
    final db = await database;
    final bookingMap = booking.toJson();
    bookingMap['status_history'] = jsonEncode(booking.statusHistory.map((e) => {
      'status': e.status,
      'timestamp': e.timestamp.toIso8601String(),
      'updatedBy': e.updatedBy,
      'notes': e.notes,
    }).toList());
    bookingMap['is_synced'] = 0;
    bookingMap['sync_version'] = (bookingMap['sync_version'] ?? 1) + 1;
    bookingMap['updated_at'] = DateTime.now().toIso8601String();
    
    await _addToSyncQueue('bookings', booking.id, 'UPDATE', jsonEncode(bookingMap));
    return await db.update('bookings', bookingMap, where: 'id = ?', whereArgs: [booking.id]);
  }

  Future<BookingModel?> getBooking(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'bookings',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      final bookingMap = Map<String, dynamic>.from(maps.first);
      if (bookingMap['status_history'] != null) {
        bookingMap['status_history'] = jsonDecode(bookingMap['status_history']);
      }
      return BookingModel.fromJson(bookingMap);
    }
    return null;
  }

  Future<List<BookingModel>> getAllBookings({String? userId}) async {
    final db = await database;
    List<Map<String, dynamic>> maps;
    
    if (userId != null) {
      maps = await db.query(
        'bookings',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );
    } else {
      maps = await db.query('bookings', orderBy: 'created_at DESC');
    }

    return maps.map((map) {
      final bookingMap = Map<String, dynamic>.from(map);
      if (bookingMap['status_history'] != null) {
        bookingMap['status_history'] = jsonDecode(bookingMap['status_history']);
      }
      return BookingModel.fromJson(bookingMap);
    }).toList();
  }

  Future<List<BookingModel>> getUnsyncedBookings() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'bookings',
      where: 'is_synced = ?',
      whereArgs: [0],
    );

    return maps.map((map) {
      final bookingMap = Map<String, dynamic>.from(map);
      if (bookingMap['status_history'] != null) {
        bookingMap['status_history'] = jsonDecode(bookingMap['status_history']);
      }
      return BookingModel.fromJson(bookingMap);
    }).toList();
  }

  // Notification operations
  Future<int> insertNotification(NotificationModel notification) async {
    final db = await database;
    final notificationMap = notification.toJson();
    notificationMap['data'] = jsonEncode(notification.data);
    notificationMap['is_synced'] = 0;
    notificationMap['sync_version'] = 1;
    notificationMap['last_sync_at'] = null;
    
    await _addToSyncQueue('notifications', notification.id, 'INSERT', jsonEncode(notificationMap));
    return await db.insert('notifications', notificationMap);
  }

  Future<int> updateNotification(NotificationModel notification) async {
    final db = await database;
    final notificationMap = notification.toJson();
    notificationMap['data'] = jsonEncode(notification.data);
    notificationMap['is_synced'] = 0;
    notificationMap['sync_version'] = (notificationMap['sync_version'] ?? 1) + 1;
    notificationMap['updated_at'] = DateTime.now().toIso8601String();
    
    await _addToSyncQueue('notifications', notification.id, 'UPDATE', jsonEncode(notificationMap));
    return await db.update('notifications', notificationMap, where: 'id = ?', whereArgs: [notification.id]);
  }

  Future<List<NotificationModel>> getAllNotifications({String? recipient}) async {
    final db = await database;
    List<Map<String, dynamic>> maps;
    
    if (recipient != null) {
      maps = await db.query(
        'notifications',
        where: 'recipient = ? OR recipient = ?',
        whereArgs: [recipient, 'all'],
        orderBy: 'created_at DESC',
      );
    } else {
      maps = await db.query('notifications', orderBy: 'created_at DESC');
    }

    return maps.map((map) {
      final notificationMap = Map<String, dynamic>.from(map);
      if (notificationMap['data'] != null) {
        notificationMap['data'] = jsonDecode(notificationMap['data']);
      }
      return NotificationModel.fromJson(notificationMap);
    }).toList();
  }

  Future<List<NotificationModel>> getUnsyncedNotifications() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notifications',
      where: 'is_synced = ?',
      whereArgs: [0],
    );

    return maps.map((map) {
      final notificationMap = Map<String, dynamic>.from(map);
      if (notificationMap['data'] != null) {
        notificationMap['data'] = jsonDecode(notificationMap['data']);
      }
      return NotificationModel.fromJson(notificationMap);
    }).toList();
  }

  // Sync queue operations
  Future<void> _addToSyncQueue(String tableName, String recordId, String operation, String data) async {
    final db = await database;
    await db.insert('sync_queue', {
      'table_name': tableName,
      'record_id': recordId,
      'operation': operation,
      'data': data,
      'created_at': DateTime.now().toIso8601String(),
      'retry_count': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    final db = await database;
    return await db.query('sync_queue', orderBy: 'created_at ASC');
  }

  Future<void> removeSyncQueueItem(int id) async {
    final db = await database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> incrementSyncRetryCount(int id) async {
    final db = await database;
    await db.update(
      'sync_queue',
      {
        'retry_count': 'retry_count + 1',
        'last_retry_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Sync metadata operations
  Future<void> setSyncMetadata(String key, String value) async {
    final db = await database;
    await db.insert(
      'sync_metadata',
      {
        'key': key,
        'value': value,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSyncMetadata(String key) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sync_metadata',
      where: 'key = ?',
      whereArgs: [key],
    );

    if (maps.isNotEmpty) {
      return maps.first['value'] as String;
    }
    return null;
  }

  // Mark records as synced
  Future<void> markBookingAsSynced(String id, int syncVersion) async {
    final db = await database;
    await db.update(
      'bookings',
      {
        'is_synced': 1,
        'sync_version': syncVersion,
        'last_sync_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markNotificationAsSynced(String id, int syncVersion) async {
    final db = await database;
    await db.update(
      'notifications',
      {
        'is_synced': 1,
        'sync_version': syncVersion,
        'last_sync_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Clear all data (for testing or reset)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('bookings');
    await db.delete('notifications');
    await db.delete('sync_queue');
    await db.delete('sync_metadata');
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}