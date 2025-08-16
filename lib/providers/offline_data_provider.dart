import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/booking_model.dart';
import '../models/notification_model.dart';
import '../services/local_database_service.dart';
import '../services/data_sync_service.dart';
import '../services/background_sync_service.dart';

class OfflineDataProvider extends ChangeNotifier {
  final LocalDatabaseService _localDb = LocalDatabaseService();
  final DataSyncService _syncService = DataSyncService();
  final BackgroundSyncService _backgroundSync = BackgroundSyncService();

  List<BookingModel> _bookings = [];
  List<NotificationModel> _notifications = [];
  bool _isOnline = true;
  bool _isInitialized = false;
  String? _currentUserId;

  // Getters
  List<BookingModel> get bookings => _bookings;
  List<NotificationModel> get notifications => _notifications;
  bool get isOnline => _isOnline;
  bool get isInitialized => _isInitialized;
  SyncStatus get syncStatus => _syncService.syncStatus;
  String? get lastSyncError => _syncService.lastSyncError;
  DateTime? get lastSyncTime => _syncService.lastSyncTime;

  // Initialize the provider
  Future<void> initialize(String userId) async {
    if (_isInitialized) return;

    _currentUserId = userId;

    try {
      // Initialize services
      _syncService.initialize();
      await _backgroundSync.initialize();

      // Load cached data
      await _loadCachedData();

      // Listen to connectivity changes
      _listenToConnectivityChanges();

      // Listen to sync service changes
      _syncService.addListener(_onSyncStatusChanged);

      _isInitialized = true;
      notifyListeners();

      // Trigger initial sync if online
      if (_isOnline) {
        _syncService.syncData();
      }
    } catch (e) {
      debugPrint('Failed to initialize OfflineDataProvider: $e');
    }
  }

  void _onSyncStatusChanged() {
    notifyListeners();
  }

  void _listenToConnectivityChanges() {
    Connectivity().onConnectivityChanged.listen((result) {
      final wasOnline = _isOnline;
      _isOnline = result != ConnectivityResult.none;

      if (!wasOnline && _isOnline) {
        // Connection restored, trigger sync
        _syncService.syncData().then((_) => _loadCachedData());
      }

      notifyListeners();
    });
  }

  Future<void> _loadCachedData() async {
    try {
      if (_currentUserId != null) {
        _bookings = await _localDb.getAllBookings(userId: _currentUserId);
        _notifications =
            await _localDb.getAllNotifications(recipient: _currentUserId);
      } else {
        _bookings = await _localDb.getAllBookings();
        _notifications = await _localDb.getAllNotifications();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load cached data: $e');
    }
  }

  // Booking operations
  Future<bool> createBooking(BookingModel booking) async {
    try {
      // Save to local database first
      await _localDb.insertBooking(booking);

      // Update local list
      _bookings.insert(0, booking);
      notifyListeners();

      // Trigger sync if online
      if (_isOnline) {
        _backgroundSync.triggerImmediateSync();
      }

      return true;
    } catch (e) {
      debugPrint('Failed to create booking: $e');
      return false;
    }
  }

  Future<bool> updateBooking(BookingModel booking) async {
    try {
      // Update in local database
      await _localDb.updateBooking(booking);

      // Update local list
      final index = _bookings.indexWhere((b) => b.id == booking.id);
      if (index != -1) {
        _bookings[index] = booking;
        notifyListeners();
      }

      // Trigger sync if online
      if (_isOnline) {
        _backgroundSync.triggerImmediateSync();
      }

      return true;
    } catch (e) {
      debugPrint('Failed to update booking: $e');
      return false;
    }
  }

  Future<BookingModel?> getBooking(String bookingId) async {
    try {
      // First check local cache
      final cachedBooking = _bookings.firstWhere(
        (b) => b.id == bookingId,
        orElse: () => BookingModel(
          id: '',
          userId: '',
          serviceType: '',
          customerName: '',
          customerPhone: '',
          customerAddress: '',
          description: '',
          preferredDate: DateTime.now(),
          preferredTime: '',
          status: '',
          paymentStatus: 'pending',
          paymentMethod: 'cash_on_service',
          createdAt: DateTime.now(),
        ),
      );

      if (cachedBooking.id.isNotEmpty) {
        return cachedBooking;
      }

      // If not in cache, check local database
      return await _localDb.getBooking(bookingId);
    } catch (e) {
      debugPrint('Failed to get booking: $e');
      return null;
    }
  }

  List<BookingModel> getBookingsByStatus(String status) {
    return _bookings.where((booking) => booking.status == status).toList();
  }

  List<BookingModel> getBookingsByUserId(String userId) {
    return _bookings.where((booking) => booking.userId == userId).toList();
  }

  // Notification operations
  Future<bool> createNotification(NotificationModel notification) async {
    try {
      // Save to local database first
      await _localDb.insertNotification(notification);

      // Update local list
      _notifications.insert(0, notification);
      notifyListeners();

      // Trigger sync if online
      if (_isOnline) {
        _backgroundSync.triggerImmediateSync();
      }

      return true;
    } catch (e) {
      debugPrint('Failed to create notification: $e');
      return false;
    }
  }

  Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      // Find and update notification
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        final updatedNotification = NotificationModel(
          id: _notifications[index].id,
          title: _notifications[index].title,
          message: _notifications[index].message,
          type: _notifications[index].type,
          recipient: _notifications[index].recipient,
          relatedBookingId: _notifications[index].relatedBookingId,
          relatedUserId: _notifications[index].relatedUserId,
          relatedEmployeeId: _notifications[index].relatedEmployeeId,
          isRead: true,
          readAt: DateTime.now(),
          priority: _notifications[index].priority,
          deliveryMethod: _notifications[index].deliveryMethod,
          deliveryStatus: _notifications[index].deliveryStatus,
          data: _notifications[index].data,
          actionRequired: _notifications[index].actionRequired,
          actionUrl: _notifications[index].actionUrl,
          createdAt: _notifications[index].createdAt,
        );

        // Update in local database
        await _localDb.updateNotification(updatedNotification);

        // Update local list
        _notifications[index] = updatedNotification;
        notifyListeners();

        // Trigger sync if online
        if (_isOnline) {
          _backgroundSync.triggerImmediateSync();
        }

        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Failed to mark notification as read: $e');
      return false;
    }
  }

  List<NotificationModel> getUnreadNotifications() {
    return _notifications
        .where((notification) => !notification.isRead)
        .toList();
  }

  int get unreadNotificationCount => getUnreadNotifications().length;

  // Sync operations
  Future<SyncResult> forcSync() async {
    final result = await _syncService.forcSync();
    if (result.success) {
      await _loadCachedData();
    }
    return result;
  }

  Future<Map<String, dynamic>> getSyncStats() async {
    return await _syncService.getSyncStats();
  }

  void clearSyncError() {
    _syncService.clearSyncError();
  }

  // Offline-specific operations
  Future<void> refreshData() async {
    if (_isOnline) {
      // If online, trigger sync and reload
      final result = await _syncService.syncData();
      if (result.success) {
        await _loadCachedData();
      }
    } else {
      // If offline, just reload from cache
      await _loadCachedData();
    }
  }

  Future<bool> hasUnsyncedChanges() async {
    final stats = await getSyncStats();
    return (stats['unsynced_bookings'] as int) > 0 ||
        (stats['unsynced_notifications'] as int) > 0;
  }

  // Search and filter operations
  List<BookingModel> searchBookings(String query) {
    if (query.isEmpty) return _bookings;

    final lowerQuery = query.toLowerCase();
    return _bookings.where((booking) {
      return booking.customerName.toLowerCase().contains(lowerQuery) ||
          booking.customerPhone.contains(query) ||
          booking.serviceType.toLowerCase().contains(lowerQuery) ||
          booking.status.toLowerCase().contains(lowerQuery) ||
          (booking.description?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  List<NotificationModel> searchNotifications(String query) {
    if (query.isEmpty) return _notifications;

    final lowerQuery = query.toLowerCase();
    return _notifications.where((notification) {
      return notification.title.toLowerCase().contains(lowerQuery) ||
          notification.message.toLowerCase().contains(lowerQuery) ||
          notification.type.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  List<BookingModel> filterBookingsByDateRange(
      DateTime startDate, DateTime endDate) {
    return _bookings.where((booking) {
      final bookingDate = booking.createdAt;
      return bookingDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
          bookingDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  // Statistics
  Map<String, int> getBookingStatusCounts() {
    final counts = <String, int>{};
    for (final booking in _bookings) {
      counts[booking.status] = (counts[booking.status] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, int> getServiceTypeCounts() {
    final counts = <String, int>{};
    for (final booking in _bookings) {
      counts[booking.serviceType] = (counts[booking.serviceType] ?? 0) + 1;
    }
    return counts;
  }

  // Cleanup
  @override
  void dispose() {
    _syncService.removeListener(_onSyncStatusChanged);
    _syncService.dispose();
    _backgroundSync.dispose();
    super.dispose();
  }
}
