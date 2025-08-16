import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/booking_model.dart';
import '../services/api_service.dart';
import '../services/production_api_service.dart';
import '../services/offline_booking_service.dart';
import '../services/notification_service.dart';
import '../constants/app_constants.dart';
import 'auth_provider.dart';

class BookingProvider with ChangeNotifier {
  final AuthProvider _authProvider;
  List<BookingModel> _bookings = [];
  List<BookingModel> _adminBookings = [];

  BookingProvider(this._authProvider);
  bool _isLoading = false;
  final OfflineBookingService _offlineService = OfflineBookingService();

  List<BookingModel> get bookings => _bookings;
  List<BookingModel> get adminBookings => _adminBookings;
  bool get isLoading => _isLoading;
  bool get isOnline => _offlineService.isOnline;

  void initialize() {
    _offlineService.initialize();
    _offlineService.addListener(_onOfflineServiceChanged);
  }

  void _onOfflineServiceChanged() {
    // Update bookings from cached data when offline service changes
    _updateBookingsFromCache();
    notifyListeners();
  }

  void _updateBookingsFromCache() {
    // Convert cached BookingModel to Booking for compatibility
    final cachedBookings = _offlineService.cachedBookings;
    _bookings = cachedBookings
        .map((bookingModel) => _convertToBooking(bookingModel))
        .toList();
    _adminBookings = _bookings; // For admin view, show all cached bookings
  }

  BookingModel _convertToBookingModel(
      Map<String, dynamic> bookingData, String userId) {
    return BookingModel(
      id: bookingData['id'] ?? 'temp_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      serviceType: bookingData['serviceType'] ?? '',
      customerName: bookingData['customerName'] ?? '',
      customerPhone: bookingData['customerPhone'] ?? '',
      customerAddress: bookingData['customerAddress'] ?? '',
      description: bookingData['description'] ?? '',
      preferredDate: DateTime.parse(
          bookingData['preferredDate'] ?? DateTime.now().toIso8601String()),
      preferredTime: bookingData['preferredTime'] ?? '',
      status: bookingData['status'] ?? AppConstants.pending,
      assignedEmployee: bookingData['assignedEmployee'],
      assignedDate: bookingData['assignedDate'] != null
          ? DateTime.parse(bookingData['assignedDate'])
          : null,
      acceptedDate: bookingData['acceptedDate'] != null
          ? DateTime.parse(bookingData['acceptedDate'])
          : null,
      rejectedDate: bookingData['rejectedDate'] != null
          ? DateTime.parse(bookingData['rejectedDate'])
          : null,
      startedDate: bookingData['startedDate'] != null
          ? DateTime.parse(bookingData['startedDate'])
          : null,
      completedDate: bookingData['completedDate'] != null
          ? DateTime.parse(bookingData['completedDate'])
          : null,
      paymentStatus: bookingData['paymentStatus'] ?? 'pending',
      paymentMethod: bookingData['paymentMethod'] ?? 'cash_on_service',
      paymentAmount: bookingData['paymentAmount']?.toDouble(),
      actualAmount: bookingData['actualAmount']?.toDouble(),
      adminNotes: bookingData['adminNotes'],
      workerNotes: bookingData['workerNotes'],
      rejectionReason: bookingData['rejectionReason'],
      createdAt: DateTime.parse(
          bookingData['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Convert BookingModel to BookingModel (for compatibility with offline service)
  BookingModel _convertToBooking(BookingModel bookingModel) {
    // Simply return the booking model as is, since we're already using BookingModel
    return bookingModel;
  }

  Future<Map<String, dynamic>> createBooking(
      Map<String, dynamic> bookingData) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Try offline-first approach
      final userId = bookingData['userId'] ?? '';
      final bookingModel = await _offlineService.createBookingOffline(
        userId: userId,
        serviceType: bookingData['serviceType'] ?? '',
        customerName: bookingData['customerName'] ?? '',
        customerPhone: bookingData['customerPhone'] ?? '',
        customerAddress: bookingData['customerAddress'] ?? '',
        description: bookingData['description'],
        preferredDate: bookingData['preferredDate'] ?? '',
        preferredTime: bookingData['preferredTime'] ?? '',
      );

      if (bookingModel != null) {
        // Send notification to admin about new booking
        await _sendBookingNotification(
          bookingId: bookingModel.id,
          type: 'booking_created',
          title: '🆕 New Booking Received!',
          message: 'New service booking from ${bookingModel.customerName}',
          recipientType: 'admin',
        );

        // Send confirmation notification to user
        await _sendBookingNotification(
          bookingId: bookingModel.id,
          type: 'booking_created',
          title: '📋 Booking Confirmed!',
          message:
              'Your service booking has been received and is under review.',
          recipientType: 'user',
        );

        _updateBookingsFromCache();
        _isLoading = false;
        notifyListeners();

        return {
          'success': true,
          'message': isOnline
              ? 'Booking created successfully'
              : 'Booking saved offline. Will sync when online.',
          'booking': bookingModel.toJson(),
        };
      } else {
        // Fallback to API if offline creation fails
        final result = await ApiService.createBooking(bookingData);
        if (result['success']) {
          // Send notifications for API-created booking
          final bookingId = result['booking']?['id'] ?? 'temp_id';
          await _sendBookingNotification(
            bookingId: bookingId,
            type: 'booking_created',
            title: '🆕 New Booking Received!',
            message: 'New service booking received via API',
            recipientType: 'admin',
          );

          await fetchUserBookings();
        }
        _isLoading = false;
        notifyListeners();
        return result;
      }
    } catch (e) {
      // Fallback to API on error
      final result = await ApiService.createBooking(bookingData);
      if (result['success']) {
        // Send notifications for API-created booking
        final bookingId = result['booking']?['id'] ?? 'temp_id';
        await _sendBookingNotification(
          bookingId: bookingId,
          type: 'booking_created',
          title: '🆕 New Booking Received!',
          message: 'New service booking received via API',
          recipientType: 'admin',
        );

        await fetchUserBookings();
      }
      _isLoading = false;
      notifyListeners();
      return result;
    }
  }

  Future<void> fetchUserBookings() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (isOnline) {
        // If online, fetch from API using phone number
        debugPrint('📡 Fetching user bookings from API...');

        // Get user phone from auth provider
        final user = _authProvider.user;
        if (user?.phone != null) {
          debugPrint('📱 Using phone: ${user!.phone}');
          final fetchedBookings =
              await ProductionApiService.getUserBookingsByPhone(user.phone);
          debugPrint('✅ Fetched ${fetchedBookings.length} user bookings');

          // Update the local booking list
          _bookings = fetchedBookings;

          // Sync with offline service if needed
          await _offlineService.forceSyncAll();
        } else {
          debugPrint('❌ No user phone found');
          _bookings = [];
        }
      } else {
        debugPrint('📱 Loading user bookings from cache (offline)...');
        // If offline, load from cache
        _updateBookingsFromCache();
      }
    } catch (e) {
      debugPrint('❌ Error fetching user bookings: $e');
      // On error, fallback to cached data
      _updateBookingsFromCache();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> updateBooking(
      String bookingId, Map<String, dynamic> updateData) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Try offline-first approach
      // First get the existing booking
      final existingBooking =
          await _offlineService.getCachedBookingStatus(bookingId);

      if (existingBooking != null) {
        // Create updated booking with new data
        final updatedBooking = existingBooking.copyWith(
          status: updateData['status'] ?? existingBooking.status,
          assignedEmployee: updateData['assignedEmployee'] ??
              existingBooking.assignedEmployee,
          assignedDate: updateData['assignedDate'] != null
              ? DateTime.parse(updateData['assignedDate'])
              : existingBooking.assignedDate,
          acceptedDate: updateData['acceptedDate'] != null
              ? DateTime.parse(updateData['acceptedDate'])
              : existingBooking.acceptedDate,
          rejectedDate: updateData['rejectedDate'] != null
              ? DateTime.parse(updateData['rejectedDate'])
              : existingBooking.rejectedDate,
          startedDate: updateData['startedDate'] != null
              ? DateTime.parse(updateData['startedDate'])
              : existingBooking.startedDate,
          completedDate: updateData['completedDate'] != null
              ? DateTime.parse(updateData['completedDate'])
              : existingBooking.completedDate,
          paymentStatus:
              updateData['paymentStatus'] ?? existingBooking.paymentStatus,
          paymentMethod:
              updateData['paymentMethod'] ?? existingBooking.paymentMethod,
          paymentAmount: updateData['paymentAmount']?.toDouble() ??
              existingBooking.paymentAmount,
          actualAmount: updateData['actualAmount']?.toDouble() ??
              existingBooking.actualAmount,
          adminNotes: updateData['adminNotes'] ?? existingBooking.adminNotes,
          workerNotes: updateData['workerNotes'] ?? existingBooking.workerNotes,
          rejectionReason:
              updateData['rejectionReason'] ?? existingBooking.rejectionReason,
        );

        final success =
            await _offlineService.updateBookingOffline(updatedBooking);

        if (success) {
          // Send notification to user about booking update
          await _sendBookingNotification(
            bookingId: bookingId,
            type: 'booking_updated',
            title: '📝 Booking Updated',
            message: 'Your service booking has been updated.',
            recipientType: 'user',
          );

          // Send notification to admin about booking update
          await _sendBookingNotification(
            bookingId: bookingId,
            type: 'booking_updated',
            title: '📝 Booking Updated',
            message: 'A service booking has been updated.',
            recipientType: 'admin',
          );

          _updateBookingsFromCache();
          _isLoading = false;
          notifyListeners();

          return {
            'success': true,
            'message': isOnline
                ? 'Booking updated successfully'
                : 'Booking update saved offline. Will sync when online.',
            'booking': updatedBooking.toJson(),
          };
        }
      }

      // Fallback to API if offline update fails
      final result = await ApiService.updateBooking(bookingId, updateData);
      if (result['success']) {
        await fetchAllBookings(); // Refresh admin bookings
      }
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      // Fallback to API on error
      final result = await ApiService.updateBooking(bookingId, updateData);
      if (result['success']) {
        await fetchAllBookings(); // Refresh admin bookings
      }
      _isLoading = false;
      notifyListeners();
      return result;
    }
  }

  Future<void> fetchAllBookings() async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('📡 Fetching admin bookings from API...');

      // Use regular API service for admin bookings
      final fetchedBookings = await ApiService.getAllBookings();
      debugPrint('✅ Fetched ${fetchedBookings.length} admin bookings');

      // Update the admin bookings list
      _adminBookings = fetchedBookings;

      // Also update user bookings for consistency
      _bookings = fetchedBookings;

      // Log booking details for debugging
      if (fetchedBookings.isNotEmpty) {
        debugPrint('📋 First booking details:');
        debugPrint('  - ID: ${fetchedBookings.first.id}');
        debugPrint('  - Customer: ${fetchedBookings.first.customerName}');
        debugPrint('  - Service: ${fetchedBookings.first.serviceType}');
        debugPrint('  - Status: ${fetchedBookings.first.status}');
      } else {
        debugPrint('⚠️ No bookings returned from API');
      }
    } catch (e) {
      debugPrint('❌ Error fetching admin bookings: $e');
      _adminBookings = [];
      _bookings = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  List<BookingModel> getBookingsByStatus(String status) {
    return _adminBookings.where((booking) => booking.status == status).toList();
  }

  int getBookingCountByStatus(String status) {
    return _adminBookings.where((booking) => booking.status == status).length;
  }

  // Accept Booking
  Future<Map<String, dynamic>> acceptBooking(String bookingId,
      {String? adminNotes}) async {
    _isLoading = true;
    notifyListeners();

    final result = await ApiService.acceptBooking(
      bookingId,
      adminNotes: adminNotes,
    );

    if (result['success']) {
      // Send notification to user
      await _sendBookingNotification(
        bookingId: bookingId,
        type: 'booking_accepted',
        title: '🎉 Booking Accepted!',
        message: 'Your service booking has been accepted by our team.',
        recipientType: 'user',
      );

      // Send notification to admin
      await _sendBookingNotification(
        bookingId: bookingId,
        type: 'booking_accepted',
        title: '✅ Booking Accepted',
        message: 'You have accepted a new service booking.',
        recipientType: 'admin',
      );

      await fetchAllBookings(); // Refresh bookings
    }

    _isLoading = false;
    notifyListeners();
    return result;
  }

  // Reject Booking
  Future<Map<String, dynamic>> rejectBooking(
      String bookingId, String rejectionReason) async {
    _isLoading = true;
    notifyListeners();

    final result = await ApiService.rejectBooking(bookingId, rejectionReason);

    if (result['success']) {
      // Send notification to user
      await _sendBookingNotification(
        bookingId: bookingId,
        type: 'booking_rejected',
        title: '❌ Booking Rejected',
        message:
            'Your service booking has been rejected. Reason: $rejectionReason',
        recipientType: 'user',
      );

      // Send notification to admin
      await _sendBookingNotification(
        bookingId: bookingId,
        type: 'booking_rejected',
        title: '❌ Booking Rejected',
        message: 'You have rejected a service booking.',
        recipientType: 'admin',
      );

      await fetchAllBookings(); // Refresh bookings
    }

    _isLoading = false;
    notifyListeners();
    return result;
  }

  // Update Admin Notes
  Future<Map<String, dynamic>> updateAdminNotes(
      String bookingId, String adminNotes) async {
    _isLoading = true;
    notifyListeners();

    final result = await ApiService.updateAdminNotes(bookingId, adminNotes);

    if (result['success']) {
      // Send notification to user about admin notes
      await _sendBookingNotification(
        bookingId: bookingId,
        type: 'admin_notes_updated',
        title: '📝 Admin Notes Updated',
        message: 'Admin has added notes to your booking.',
        recipientType: 'user',
      );

      await fetchAllBookings(); // Refresh bookings
    }

    _isLoading = false;
    notifyListeners();
    return result;
  }

  // Assign Worker to Booking
  Future<Map<String, dynamic>> assignWorker(
      String bookingId, String workerId) async {
    _isLoading = true;
    notifyListeners();

    final result = await ApiService.assignWorker(bookingId, workerId);

    if (result['success']) {
      // Send notification to user
      await _sendBookingNotification(
        bookingId: bookingId,
        type: 'worker_assigned',
        title: '👷 Worker Assigned!',
        message: 'A worker has been assigned to your service booking.',
        recipientType: 'user',
      );

      // Send notification to admin
      await _sendBookingNotification(
        bookingId: bookingId,
        type: 'worker_assigned',
        title: '👷 Worker Assigned',
        message: 'You have assigned a worker to a service booking.',
        recipientType: 'admin',
      );

      await fetchAllBookings(); // Refresh bookings
    }

    _isLoading = false;
    notifyListeners();
    return result;
  }

  // Start Work
  Future<Map<String, dynamic>> startWork(String bookingId,
      {String? workerNotes}) async {
    _isLoading = true;
    notifyListeners();

    final result =
        await ApiService.startWork(bookingId, workerNotes: workerNotes);

    if (result['success']) {
      // Send notification to user
      await _sendBookingNotification(
        bookingId: bookingId,
        type: 'service_started',
        title: '🔧 Service Started!',
        message: 'Your service has started. Our worker is now on the job.',
        recipientType: 'user',
      );

      // Send notification to admin
      await _sendBookingNotification(
        bookingId: bookingId,
        type: 'service_started',
        title: '🔧 Service Started',
        message: 'A service has been started for a booking.',
        recipientType: 'admin',
      );

      await fetchAllBookings(); // Refresh bookings
    }

    _isLoading = false;
    notifyListeners();
    return result;
  }

  // Complete Work
  Future<Map<String, dynamic>> completeWork(
    String bookingId, {
    String? workerNotes,
    double? actualAmount,
  }) async {
    _isLoading = true;
    notifyListeners();

    final result = await ApiService.completeWork(
      bookingId,
      workerNotes: workerNotes,
      actualAmount: actualAmount,
    );

    if (result['success']) {
      // Send notification to user
      await _sendBookingNotification(
        bookingId: bookingId,
        type: 'service_completed',
        title: '✅ Service Completed!',
        message: 'Your service has been completed. Payment is now required.',
        recipientType: 'user',
      );

      // Send notification to admin
      await _sendBookingNotification(
        bookingId: bookingId,
        type: 'service_completed',
        title: '✅ Service Completed',
        message: 'A service has been completed. Payment processing required.',
        recipientType: 'admin',
      );

      await fetchAllBookings(); // Refresh bookings
    }

    _isLoading = false;
    notifyListeners();
    return result;
  }

  // Complete Payment
  Future<Map<String, dynamic>> completePayment(
    String bookingId,
    double actualAmount,
    String paymentMethod,
  ) async {
    _isLoading = true;
    notifyListeners();

    print('💳 Processing payment for booking: $bookingId');
    print('💰 Amount: $actualAmount, Method: $paymentMethod');

    final result = await ApiService.completePayment(
        bookingId, actualAmount, paymentMethod);

    print('💳 Payment result: ${result['success']}');
    if (result['message'] != null) {
      print('💳 Payment message: ${result['message']}');
    }

    if (result['success']) {
      // Send notification to user
      await _sendBookingNotification(
        bookingId: bookingId,
        type: 'payment_received',
        title: '💳 Payment Received!',
        message: 'Thank you! Your payment has been received successfully.',
        recipientType: 'user',
      );

      // Send notification to admin
      await _sendBookingNotification(
        bookingId: bookingId,
        type: 'payment_received',
        title: '💳 Payment Received',
        message: 'Payment has been received for a completed service.',
        recipientType: 'admin',
      );

      await fetchAllBookings(); // Refresh bookings
      await fetchUserBookings(); // Refresh user bookings too
      print('✅ Payment completed successfully, bookings refreshed');
    } else {
      print('❌ Payment failed: ${result['message']}');
    }

    _isLoading = false;
    notifyListeners();
    return result;
  }

  // Helper method to send booking notifications
  Future<void> _sendBookingNotification({
    required String bookingId,
    required String type,
    required String title,
    required String message,
    required String recipientType,
  }) async {
    try {
      final notificationData = {
        'title': title,
        'message': message,
        'type': type,
        'relatedBooking': bookingId,
        'recipientType': recipientType,
        'priority': 'high',
        'category': 'booking_update',
      };

      // Send to backend based on recipient type
      if (recipientType == 'user') {
        await NotificationService.createUserNotification(
          _authProvider.user?.id ?? 'unknown',
          notificationData,
        );
      } else if (recipientType == 'admin') {
        await NotificationService.createAdminNotification(notificationData);
      }

      // Also create local notification for immediate feedback
      if (recipientType == 'user') {
        // Create local notification for user
        await _createLocalNotification(notificationData);
      }

      debugPrint('📱 Notification sent: $title - $message');
    } catch (e) {
      debugPrint('❌ Failed to send notification: $e');
    }
  }

  // Create local notification
  Future<void> _createLocalNotification(
      Map<String, dynamic> notificationData) async {
    try {
      // This will create a local notification for immediate user feedback
      // You can integrate with flutter_local_notifications package here
      debugPrint('📱 Local notification created: ${notificationData['title']}');
    } catch (e) {
      debugPrint('❌ Failed to create local notification: $e');
    }
  }

  // Get Available Workers
  Future<List<Map<String, dynamic>>> getAvailableWorkers(
      {String? serviceType}) async {
    if (serviceType == null) return [];

    final response =
        await ApiService.getAvailableWorkers(serviceType: serviceType);
    if (response['success'] == true && response['employees'] != null) {
      return List<Map<String, dynamic>>.from(response['employees']);
    }
    return [];
  }

  // Helper methods for filtering bookings
  List<BookingModel> getPendingBookings() {
    return _adminBookings
        .where((booking) => booking.status == AppConstants.pending)
        .toList();
  }

  List<BookingModel> getAcceptedBookings() {
    return _adminBookings
        .where((booking) => booking.status == AppConstants.accepted)
        .toList();
  }

  List<BookingModel> getAssignedBookings() {
    return _adminBookings
        .where((booking) => booking.status == AppConstants.assigned)
        .toList();
  }

  List<BookingModel> getInProgressBookings() {
    return _adminBookings
        .where((booking) => booking.status == AppConstants.inProgress)
        .toList();
  }

  List<BookingModel> getCompletedBookings() {
    return _adminBookings
        .where((booking) => booking.status == AppConstants.completed)
        .toList();
  }

  List<BookingModel> getRejectedBookings() {
    return _adminBookings
        .where((booking) => booking.status == AppConstants.rejected)
        .toList();
  }

  // Get bookings that need payment processing
  List<BookingModel> getBookingsNeedingPayment() {
    return _adminBookings
        .where((booking) =>
            booking.status == AppConstants.completed &&
            booking.paymentStatus == AppConstants.paymentPending)
        .toList();
  }

  // Offline-specific methods
  Future<BookingModel?> getCachedBookingStatus(String bookingId) async {
    final bookingModel =
        await _offlineService.getCachedBookingStatus(bookingId);
    return bookingModel != null ? _convertToBooking(bookingModel) : null;
  }

  List<BookingModel> getCachedUserBookings(String userId) {
    final cachedBookings = _offlineService.getCachedUserBookings(userId);
    return cachedBookings
        .map((bookingModel) => _convertToBooking(bookingModel))
        .toList();
  }

  List<BookingModel> getOfflineBookings() {
    final offlineBookings = _offlineService.getOfflineBookings();
    return offlineBookings
        .map((bookingModel) => _convertToBooking(bookingModel))
        .toList();
  }

  Future<Map<String, dynamic>> getSyncStatistics() async {
    return await _offlineService.getSyncStatistics();
  }

  Future<void> refreshCachedData() async {
    await _offlineService.refreshCachedData();
    _updateBookingsFromCache();
    notifyListeners();
  }

  List<BookingModel> searchBookings(String query) {
    final searchResults = _offlineService.searchCachedBookings(query);
    return searchResults
        .map((bookingModel) => _convertToBooking(bookingModel))
        .toList();
  }

  List<BookingModel> filterBookingsByDateRange(
      DateTime startDate, DateTime endDate) {
    final filteredResults =
        _offlineService.filterBookingsByDateRange(startDate, endDate);
    return filteredResults
        .map((bookingModel) => _convertToBooking(bookingModel))
        .toList();
  }

  @override
  void dispose() {
    _offlineService.removeListener(_onOfflineServiceChanged);
    super.dispose();
  }
}
