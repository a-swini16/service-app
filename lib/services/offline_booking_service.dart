import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/booking_model.dart';
import '../models/notification_model.dart';
import 'local_database_service.dart';
import 'api_service.dart';
import 'data_sync_service.dart';

enum OfflineBookingStatus { draft, pendingSync, synced, syncFailed }

class OfflineBookingService extends ChangeNotifier {
  static final OfflineBookingService _instance =
      OfflineBookingService._internal();
  factory OfflineBookingService() => _instance;
  OfflineBookingService._internal();

  final LocalDatabaseService _localDb = LocalDatabaseService();
  final ApiService _apiService = ApiService();
  final DataSyncService _syncService = DataSyncService();

  bool _isOnline = true;
  List<BookingModel> _cachedBookings = [];
  List<NotificationModel> _cachedNotifications = [];
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  // Getters
  bool get isOnline => _isOnline;
  List<BookingModel> get cachedBookings => _cachedBookings;
  List<NotificationModel> get cachedNotifications => _cachedNotifications;

  void initialize() {
    _listenToConnectivityChanges();
    _loadCachedData();
  }

  void _listenToConnectivityChanges() {
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((result) {
      final wasOnline = _isOnline;
      _isOnline = result != ConnectivityResult.none;

      if (!wasOnline && _isOnline) {
        // Connection restored, sync pending bookings
        _syncPendingBookings();
      }

      notifyListeners();
    });
  }

  Future<void> _loadCachedData() async {
    try {
      _cachedBookings = await _localDb.getAllBookings();
      _cachedNotifications = await _localDb.getAllNotifications();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load cached data: $e');
    }
  }

  // Offline booking creation
  Future<BookingModel?> createBookingOffline({
    required String userId,
    required String serviceType,
    required String customerName,
    required String customerPhone,
    required String customerAddress,
    String? description,
    required String preferredDate,
    required String preferredTime,
  }) async {
    try {
      final bookingId = 'offline_${DateTime.now().millisecondsSinceEpoch}';
      final now = DateTime.now();

      final booking = BookingModel(
        id: bookingId,
        userId: userId,
        serviceType: serviceType,
        customerName: customerName,
        customerPhone: customerPhone,
        customerAddress: customerAddress,
        description: description ?? '',
        preferredDate: DateTime.parse(preferredDate),
        preferredTime: preferredTime,
        status: _isOnline ? 'pending' : 'draft', // Mark as draft if offline
        paymentMethod: 'cash_on_service',
        paymentStatus: 'pending',
        createdAt: now,
      );

      // Save to local database
      await _localDb.insertBooking(booking);

      // Update cached list
      _cachedBookings.insert(0, booking);
      notifyListeners();

      // Create local notification
      await _createLocalNotification(
        title: 'Booking Created',
        message: _isOnline
            ? 'Your ${serviceType.replaceAll('_', ' ')} booking has been created and sent for approval.'
            : 'Your ${serviceType.replaceAll('_', ' ')} booking has been saved offline. It will be sent when you\'re back online.',
        type: 'booking_created',
        relatedBooking: bookingId,
        recipient: userId,
      );

      // If online, try to sync immediately
      if (_isOnline) {
        _syncBookingToServer(booking);
      }

      return booking;
    } catch (e) {
      debugPrint('Failed to create offline booking: $e');
      return null;
    }
  }

  // Update booking offline
  Future<bool> updateBookingOffline(BookingModel booking) async {
    try {
      final updatedBooking = booking;

      // Update in local database
      await _localDb.updateBooking(updatedBooking);

      // Update cached list
      final index = _cachedBookings.indexWhere((b) => b.id == booking.id);
      if (index != -1) {
        _cachedBookings[index] = updatedBooking;
        notifyListeners();
      }

      // If online, try to sync immediately
      if (_isOnline) {
        _syncBookingToServer(updatedBooking);
      }

      return true;
    } catch (e) {
      debugPrint('Failed to update offline booking: $e');
      return false;
    }
  }

  // Get cached booking status
  Future<BookingModel?> getCachedBookingStatus(String bookingId) async {
    try {
      // First check memory cache
      final cachedBooking = _cachedBookings.firstWhere(
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
          paymentMethod: 'cash_on_service',
          paymentStatus: 'pending',
          createdAt: DateTime.now(),
        ),
      );

      if (cachedBooking.id.isNotEmpty) {
        return cachedBooking;
      }

      // If not in memory, check local database
      return await _localDb.getBooking(bookingId);
    } catch (e) {
      debugPrint('Failed to get cached booking status: $e');
      return null;
    }
  }

  // Get all cached bookings for a user
  List<BookingModel> getCachedUserBookings(String userId) {
    return _cachedBookings
        .where((booking) => booking.userId == userId)
        .toList();
  }

  // Get bookings by status
  List<BookingModel> getCachedBookingsByStatus(String status) {
    return _cachedBookings
        .where((booking) => booking.status == status)
        .toList();
  }

  // Get offline/draft bookings
  List<BookingModel> getOfflineBookings() {
    return _cachedBookings
        .where((booking) =>
            booking.status == 'draft' || booking.id.startsWith('offline_'))
        .toList();
  }

  // Create local notification
  Future<void> _createLocalNotification({
    required String title,
    required String message,
    required String type,
    required String recipient,
    String? relatedBooking,
    String? relatedUser,
    String? relatedEmployee,
  }) async {
    try {
      final notificationId = 'local_${DateTime.now().millisecondsSinceEpoch}';
      final now = DateTime.now();

      final notification = NotificationModel(
        id: notificationId,
        title: title,
        message: message,
        type: type,
        recipient: recipient,
        relatedBookingId: relatedBooking,
        relatedUserId: relatedUser,
        relatedEmployeeId: relatedEmployee,
        isRead: false,
        priority: 'medium',
        deliveryMethod: 'in_app',
        deliveryStatus: 'delivered',
        data: {},
        actionRequired: false,
        createdAt: now,
      );

      // Save to local database
      await _localDb.insertNotification(notification);

      // Update cached list
      _cachedNotifications.insert(0, notification);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to create local notification: $e');
    }
  }

  // Sync booking to server
  Future<void> _syncBookingToServer(BookingModel booking) async {
    try {
      if (!_isOnline) return;

      Map<String, dynamic> response;

      if (booking.id.startsWith('offline_')) {
        // Create new booking on server
        response = await ApiService.createBooking(booking.toJson());
      } else {
        // Update existing booking
        response = await _apiService.updateBookingRecord(
                booking.id, booking.toJson()) ??
            {};
      }

      if (response['success'] == true) {
        // Update local booking with server data
        final serverBooking = BookingModel.fromJson(response['booking']);
        await _localDb.updateBooking(serverBooking);
        await _localDb.markBookingAsSynced(serverBooking.id, 1);

        // Update cached list
        final index = _cachedBookings.indexWhere((b) => b.id == booking.id);
        if (index != -1) {
          _cachedBookings[index] = serverBooking;
          notifyListeners();
        }

        // Create success notification
        await _createLocalNotification(
          title: 'Booking Synced',
          message: 'Your booking has been successfully synced with the server.',
          type: 'sync_success',
          recipient: booking.userId,
          relatedBooking: serverBooking.id,
        );
      }
    } catch (e) {
      debugPrint('Failed to sync booking to server: $e');

      // Create error notification
      await _createLocalNotification(
        title: 'Sync Failed',
        message:
            'Failed to sync your booking. It will be retried automatically.',
        type: 'sync_failed',
        recipient: booking.userId,
        relatedBooking: booking.id,
      );
    }
  }

  // Sync all pending bookings
  Future<void> _syncPendingBookings() async {
    try {
      final unsyncedBookings = await _localDb.getUnsyncedBookings();

      for (final booking in unsyncedBookings) {
        await _syncBookingToServer(booking);
        // Add delay to avoid overwhelming the server
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      debugPrint('Failed to sync pending bookings: $e');
    }
  }

  // Offline notification management
  Future<void> markNotificationAsReadOffline(String notificationId) async {
    try {
      final index =
          _cachedNotifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        final updatedNotification = NotificationModel(
          id: _cachedNotifications[index].id,
          title: _cachedNotifications[index].title,
          message: _cachedNotifications[index].message,
          type: _cachedNotifications[index].type,
          recipient: _cachedNotifications[index].recipient,
          relatedBookingId: _cachedNotifications[index].relatedBookingId,
          relatedUserId: _cachedNotifications[index].relatedUserId,
          relatedEmployeeId: _cachedNotifications[index].relatedEmployeeId,
          isRead: true,
          readAt: DateTime.now(),
          priority: _cachedNotifications[index].priority,
          deliveryMethod: _cachedNotifications[index].deliveryMethod,
          deliveryStatus: _cachedNotifications[index].deliveryStatus,
          data: _cachedNotifications[index].data,
          actionRequired: _cachedNotifications[index].actionRequired,
          actionUrl: _cachedNotifications[index].actionUrl,
          createdAt: _cachedNotifications[index].createdAt,
        );

        // Update in local database
        await _localDb.updateNotification(updatedNotification);

        // Update cached list
        _cachedNotifications[index] = updatedNotification;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to mark notification as read offline: $e');
    }
  }

  // Get cached notifications for user
  List<NotificationModel> getCachedUserNotifications(String userId) {
    return _cachedNotifications
        .where((notification) =>
            notification.recipient == userId || notification.recipient == 'all')
        .toList();
  }

  // Get unread notifications count
  int getUnreadNotificationCount(String userId) {
    return getCachedUserNotifications(userId)
        .where((notification) => !notification.isRead)
        .length;
  }

  // Refresh cached data
  Future<void> refreshCachedData() async {
    await _loadCachedData();
  }

  // Force sync all data
  Future<bool> forceSyncAll() async {
    if (!_isOnline) return false;

    try {
      final result = await _syncService.syncData();
      if (result.success) {
        await _loadCachedData();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Failed to force sync all data: $e');
      return false;
    }
  }

  // Get sync statistics
  Future<Map<String, dynamic>> getSyncStatistics() async {
    final unsyncedBookings = await _localDb.getUnsyncedBookings();
    final unsyncedNotifications = await _localDb.getUnsyncedNotifications();
    final offlineBookings = getOfflineBookings();

    return {
      'total_bookings': _cachedBookings.length,
      'total_notifications': _cachedNotifications.length,
      'unsynced_bookings': unsyncedBookings.length,
      'unsynced_notifications': unsyncedNotifications.length,
      'offline_bookings': offlineBookings.length,
      'is_online': _isOnline,
      'last_sync': await _localDb.getSyncMetadata('last_sync_time'),
    };
  }

  // Search cached bookings
  List<BookingModel> searchCachedBookings(String query) {
    if (query.isEmpty) return _cachedBookings;

    final lowerQuery = query.toLowerCase();
    return _cachedBookings.where((booking) {
      return booking.customerName.toLowerCase().contains(lowerQuery) ||
          booking.customerPhone.contains(query) ||
          booking.serviceType.toLowerCase().contains(lowerQuery) ||
          booking.status.toLowerCase().contains(lowerQuery) ||
          (booking.description?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  // Filter bookings by date range
  List<BookingModel> filterBookingsByDateRange(
      DateTime startDate, DateTime endDate) {
    return _cachedBookings.where((booking) {
      final bookingDate = booking.createdAt;
      return bookingDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
          bookingDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
