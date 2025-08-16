import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../utils/logger.dart';
import '../models/booking_model.dart';
import '../models/notification_model.dart';
import 'local_database_service.dart';
import 'api_service.dart';

enum SyncStatus { idle, syncing, error, completed }

enum ConflictResolution { serverWins, clientWins, merge }

class SyncResult {
  final bool success;
  final String? error;
  final int syncedItems;
  final int failedItems;

  SyncResult({
    required this.success,
    this.error,
    required this.syncedItems,
    required this.failedItems,
  });
}

class DataSyncService extends ChangeNotifier {
  static final DataSyncService _instance = DataSyncService._internal();
  factory DataSyncService() => _instance;
  DataSyncService._internal();

  final LocalDatabaseService _localDb = LocalDatabaseService();
  final ApiService _apiService = ApiService();
  final Connectivity _connectivity = Connectivity();

  SyncStatus _syncStatus = SyncStatus.idle;
  String? _lastSyncError;
  DateTime? _lastSyncTime;
  Timer? _backgroundSyncTimer;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  // Configuration
  static const int maxRetryAttempts = 3;
  static const Duration syncInterval = Duration(minutes: 5);
  static const Duration retryDelay = Duration(seconds: 30);

  SyncStatus get syncStatus => _syncStatus;
  String? get lastSyncError => _lastSyncError;
  DateTime? get lastSyncTime => _lastSyncTime;

  void initialize() {
    _startBackgroundSync();
    _listenToConnectivityChanges();
  }

  @override
  void dispose() {
    _backgroundSyncTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void _startBackgroundSync() {
    _backgroundSyncTimer = Timer.periodic(syncInterval, (timer) {
      if (_syncStatus == SyncStatus.idle) {
        syncData();
      }
    });
  }

  void _listenToConnectivityChanges() {
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none && _syncStatus == SyncStatus.idle) {
        // Connection restored, trigger sync
        Future.delayed(const Duration(seconds: 2), () => syncData());
      }
    });
  }

  Future<bool> isOnline() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<SyncResult> syncData() async {
    if (_syncStatus == SyncStatus.syncing) {
      return SyncResult(
          success: false,
          error: 'Sync already in progress',
          syncedItems: 0,
          failedItems: 0);
    }

    if (!await isOnline()) {
      return SyncResult(
          success: false,
          error: 'No internet connection',
          syncedItems: 0,
          failedItems: 0);
    }

    _setSyncStatus(SyncStatus.syncing);
    _lastSyncError = null;

    try {
      int totalSynced = 0;
      int totalFailed = 0;

      // Sync bookings
      final bookingResult = await _syncBookings();
      totalSynced += bookingResult.syncedItems;
      totalFailed += bookingResult.failedItems;

      // Sync notifications
      final notificationResult = await _syncNotifications();
      totalSynced += notificationResult.syncedItems;
      totalFailed += notificationResult.failedItems;

      // Download latest data from server
      await _downloadLatestData();

      _lastSyncTime = DateTime.now();
      await _localDb.setSyncMetadata(
          'last_sync_time', _lastSyncTime!.toIso8601String());

      _setSyncStatus(SyncStatus.completed);

      // Reset to idle after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        _setSyncStatus(SyncStatus.idle);
      });

      return SyncResult(
        success: totalFailed == 0,
        syncedItems: totalSynced,
        failedItems: totalFailed,
      );
    } catch (e) {
      _lastSyncError = e.toString();
      _setSyncStatus(SyncStatus.error);

      // Reset to idle after error delay
      Future.delayed(retryDelay, () {
        _setSyncStatus(SyncStatus.idle);
      });

      return SyncResult(
        success: false,
        error: e.toString(),
        syncedItems: 0,
        failedItems: 0,
      );
    }
  }

  Future<SyncResult> _syncBookings() async {
    int synced = 0;
    int failed = 0;

    try {
      final unsyncedBookings = await _localDb.getUnsyncedBookings();

      for (final booking in unsyncedBookings) {
        try {
          final serverBooking = await _uploadBooking(booking);
          if (serverBooking != null) {
            await _localDb.markBookingAsSynced(
                booking.id, serverBooking['sync_version'] ?? 1);
            synced++;
          } else {
            failed++;
          }
        } catch (e) {
          Logger.error('Failed to sync booking ${booking.id}', error: e);
          failed++;
        }
      }

      return SyncResult(
          success: failed == 0, syncedItems: synced, failedItems: failed);
    } catch (e) {
      Logger.error('Error syncing bookings', error: e);
      return SyncResult(
          success: false,
          error: e.toString(),
          syncedItems: synced,
          failedItems: failed);
    }
  }

  Future<SyncResult> _syncNotifications() async {
    int synced = 0;
    int failed = 0;

    try {
      final unsyncedNotifications = await _localDb.getUnsyncedNotifications();

      for (final notification in unsyncedNotifications) {
        try {
          final serverNotification = await _uploadNotification(notification);
          if (serverNotification != null) {
            await _localDb.markNotificationAsSynced(
                notification.id, serverNotification['sync_version'] ?? 1);
            synced++;
          } else {
            failed++;
          }
        } catch (e) {
          Logger.error('Failed to sync notification ${notification.id}', error: e);
          failed++;
        }
      }

      return SyncResult(
          success: failed == 0, syncedItems: synced, failedItems: failed);
    } catch (e) {
      Logger.error('Error syncing notifications', error: e);
      return SyncResult(
          success: false,
          error: e.toString(),
          syncedItems: synced,
          failedItems: failed);
    }
  }

  Future<Map<String, dynamic>?> _uploadBooking(BookingModel booking) async {
    try {
      // Check if booking exists on server
      final existingBooking = await _apiService.getBooking(booking.id);

      if (existingBooking != null) {
        // Booking exists, handle conflict resolution
        final resolvedBooking =
            await _resolveBookingConflict(booking, existingBooking);
        if (resolvedBooking != null) {
          return await _apiService.updateBookingRecord(
              resolvedBooking.id, resolvedBooking.toJson());
        }
      } else {
        // New booking, create on server
        return await ApiService.createBooking(booking.toJson());
      }
    } catch (e) {
      Logger.error('Error uploading booking', error: e);
      rethrow;
    }
    return null;
  }

  Future<Map<String, dynamic>?> _uploadNotification(
      NotificationModel notification) async {
    try {
      // For notifications, we typically don't update existing ones
      // Just ensure they exist on the server
      return await _apiService.createNotification(notification.toJson());
    } catch (e) {
      Logger.error('Error uploading notification', error: e);
      rethrow;
    }
  }

  Future<BookingModel?> _resolveBookingConflict(
      BookingModel localBooking, Map<String, dynamic> serverBooking) async {
    // Implement conflict resolution strategy
    final serverUpdatedAt = DateTime.parse(
        serverBooking['updated_at'] ?? serverBooking['createdAt']);
    final localUpdatedAt = localBooking.createdAt;

    // Default strategy: Server wins for most fields, but preserve local changes for user-specific data
    if (serverUpdatedAt.isAfter(localUpdatedAt)) {
      // Server is newer, but check for local changes that should be preserved
      final mergedBooking = BookingModel.fromJson(serverBooking);

      // Preserve local user-specific changes if they're more recent
      if (localBooking.customerName != mergedBooking.customerName ||
          localBooking.customerPhone != mergedBooking.customerPhone ||
          localBooking.customerAddress != mergedBooking.customerAddress) {
        // User made local changes, preserve them
        return BookingModel(
          id: mergedBooking.id,
          userId: mergedBooking.userId,
          serviceType: mergedBooking.serviceType,
          customerName: localBooking.customerName,
          customerPhone: localBooking.customerPhone,
          customerAddress: localBooking.customerAddress,
          description: localBooking.description,
          preferredDate: localBooking.preferredDate,
          preferredTime: localBooking.preferredTime,
          status: mergedBooking.status, // Server status wins
          assignedEmployee: mergedBooking.assignedEmployee,
          assignedDate: mergedBooking.assignedDate,
          acceptedDate: mergedBooking.acceptedDate,
          rejectedDate: mergedBooking.rejectedDate,
          startedDate: mergedBooking.startedDate,
          completedDate: mergedBooking.completedDate,
          paymentStatus: mergedBooking.paymentStatus,
          paymentMethod: mergedBooking.paymentMethod,
          paymentAmount: mergedBooking.paymentAmount,
          actualAmount: mergedBooking.actualAmount,
          adminNotes: mergedBooking.adminNotes,
          workerNotes: mergedBooking.workerNotes,
          rejectionReason: mergedBooking.rejectionReason,
          createdAt: mergedBooking.createdAt,
        );
      }

      return mergedBooking;
    } else {
      // Local is newer or same, upload local version
      return localBooking;
    }
  }

  Future<void> _downloadLatestData() async {
    try {
      // Get last sync time
      final lastSyncTimeStr = await _localDb.getSyncMetadata('last_sync_time');
      DateTime? lastSyncTime;
      if (lastSyncTimeStr != null) {
        lastSyncTime = DateTime.parse(lastSyncTimeStr);
      }

      // Download updated bookings
      final updatedBookings =
          await _apiService.getUpdatedBookings(lastSyncTime);
      for (final bookingData in updatedBookings) {
        final booking = BookingModel.fromJson(bookingData);
        final existingBooking = await _localDb.getBooking(booking.id);

        if (existingBooking != null) {
          // Update existing booking
          await _localDb.updateBooking(booking);
        } else {
          // Insert new booking
          await _localDb.insertBooking(booking);
        }

        // Mark as synced since it came from server
        await _localDb.markBookingAsSynced(
            booking.id, bookingData['sync_version'] ?? 1);
      }

      // Download updated notifications
      final updatedNotifications =
          await _apiService.getUpdatedNotifications(lastSyncTime);
      for (final notificationData in updatedNotifications) {
        final notification = NotificationModel.fromJson(notificationData);
        final existingNotification = await _localDb.getAllNotifications();
        final exists = existingNotification.any((n) => n.id == notification.id);

        if (exists) {
          // Update existing notification
          await _localDb.updateNotification(notification);
        } else {
          // Insert new notification
          await _localDb.insertNotification(notification);
        }

        // Mark as synced since it came from server
        await _localDb.markNotificationAsSynced(
            notification.id, notificationData['sync_version'] ?? 1);
      }
    } catch (e) {
      Logger.error('Error downloading latest data', error: e);
      rethrow;
    }
  }

  void _setSyncStatus(SyncStatus status) {
    _syncStatus = status;
    notifyListeners();
  }

  // Manual sync trigger
  Future<SyncResult> forcSync() async {
    return await syncData();
  }

  // Get sync statistics
  Future<Map<String, dynamic>> getSyncStats() async {
    final unsyncedBookings = await _localDb.getUnsyncedBookings();
    final unsyncedNotifications = await _localDb.getUnsyncedNotifications();
    final pendingSyncItems = await _localDb.getPendingSyncItems();

    return {
      'unsynced_bookings': unsyncedBookings.length,
      'unsynced_notifications': unsyncedNotifications.length,
      'pending_sync_items': pendingSyncItems.length,
      'last_sync_time': _lastSyncTime?.toIso8601String(),
      'sync_status': _syncStatus.toString(),
      'last_error': _lastSyncError,
    };
  }

  // Clear sync errors
  void clearSyncError() {
    _lastSyncError = null;
    if (_syncStatus == SyncStatus.error) {
      _setSyncStatus(SyncStatus.idle);
    }
  }
}
