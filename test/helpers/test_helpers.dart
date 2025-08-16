import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:om_enterprises/providers/auth_provider.dart';
import 'package:om_enterprises/providers/booking_provider.dart';
import 'package:om_enterprises/providers/notification_provider.dart';
import 'package:om_enterprises/providers/service_provider.dart';
import 'package:om_enterprises/models/user_model.dart';
import 'package:om_enterprises/models/booking_model.dart';
import 'package:om_enterprises/models/service_model.dart';
import 'package:om_enterprises/models/notification_model.dart';

class TestHelpers {
  static Widget createTestApp({
    required Widget child,
    AuthProvider? authProvider,
    BookingProvider? bookingProvider,
    NotificationProvider? notificationProvider,
    ServiceProvider? serviceProvider,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => authProvider ?? MockAuthProvider(),
        ),
        ChangeNotifierProvider<BookingProvider>(
          create: (_) => bookingProvider ?? MockBookingProvider(),
        ),
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) => notificationProvider ?? MockNotificationProvider(),
        ),
        ChangeNotifierProvider<ServiceProvider>(
          create: (_) => serviceProvider ?? MockServiceProvider(),
        ),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  static UserModel createTestUser() {
    return UserModel(
      id: 'test-user-id',
      name: 'Test User',
      email: 'test@example.com',
      phone: '1234567890',
      address: '123 Test Street',
      createdAt: DateTime.now(),
    );
  }

  static BookingModel createTestBooking() {
    return BookingModel(
      id: 'test-booking-id',
      userId: 'test-user-id',
      serviceType: 'water_purifier',
      customerName: 'Test Customer',
      customerPhone: '1234567890',
      customerAddress: '123 Test Street',
      description: 'Test booking description',
      preferredDate: DateTime.now(),
      preferredTime: '10:00 AM',
      status: 'pending',
      paymentStatus: 'pending',
      paymentMethod: 'cash_on_service',
      createdAt: DateTime.now(),
    );
  }

  static ServiceModel createTestService() {
    return ServiceModel(
      id: 'test-service-id',
      name: 'water_purifier',
      displayName: 'Water Purifier Service',
      description: 'Professional water purifier maintenance',
      basePrice: 500.0,
      category: 'water_purifier',
      duration: 60,
      isActive: true,
    );
  }

  static NotificationModel createTestNotification() {
    return NotificationModel(
      id: 'test-notification-id',
      title: 'Test Notification',
      message: 'This is a test notification',
      type: 'booking_accepted',
      recipient: 'test-user-id',
      isRead: false,
      priority: 'medium',
      createdAt: DateTime.now(),
    );
  }
}

// Mock Providers for Testing
class MockAuthProvider extends AuthProvider {
  bool _isAuthenticated = true;
  UserModel? _user = TestHelpers.createTestUser();

  @override
  bool get isAuthenticated => _isAuthenticated;

  @override
  UserModel? get user => _user;

  @override
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _isAuthenticated = true;
    _user = TestHelpers.createTestUser();
    notifyListeners();
    return {'success': true, 'user': _user!.toJson()};
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _isAuthenticated = false;
    _user = null;
    notifyListeners();
  }

  @override
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String address,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _isAuthenticated = true;
    _user = UserModel(
      id: 'new-user-id',
      name: name,
      email: email,
      phone: phone,
      address: address,
      createdAt: DateTime.now(),
    );
    notifyListeners();
    return {'success': true, 'user': _user!.toJson()};
  }
}

class MockBookingProvider extends BookingProvider {
  final List<BookingModel> _bookings = [TestHelpers.createTestBooking()];
  bool _mockIsLoading = false;

  MockBookingProvider() : super(MockAuthProvider());

  @override
  List<BookingModel> get bookings => _bookings;

  @override
  bool get isLoading => _mockIsLoading;

  void setLoading(bool loading) {
    _mockIsLoading = loading;
    notifyListeners();
  }

  void clearBookings() {
    _bookings.clear();
    notifyListeners();
  }

  void addBooking(BookingModel booking) {
    _bookings.add(booking);
    notifyListeners();
  }

  BookingModel? getBookingById(String id) {
    try {
      return _bookings.firstWhere((booking) => booking.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>> createBooking(
      Map<String, dynamic> bookingData) async {
    _mockIsLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 200));

    final newBooking = BookingModel(
      id: 'new-booking-${_bookings.length}',
      userId: 'test-user-id',
      serviceType: bookingData['serviceType'] ?? 'water_purifier',
      customerName: bookingData['customerName'] ?? 'Test Customer',
      customerPhone: bookingData['customerPhone'] ?? '1234567890',
      customerAddress: bookingData['customerAddress'] ?? '123 Test Street',
      description: bookingData['description'] ?? 'Test description',
      preferredDate: DateTime.parse(
          bookingData['preferredDate'] ?? DateTime.now().toIso8601String()),
      preferredTime: bookingData['preferredTime'] ?? '10:00 AM',
      status: 'pending',
      paymentStatus: 'pending',
      paymentMethod: 'cash_on_service',
      createdAt: DateTime.now(),
    );

    _bookings.add(newBooking);
    _mockIsLoading = false;
    notifyListeners();
    return {'success': true, 'booking': newBooking.toJson()};
  }

  @override
  Future<void> fetchUserBookings() async {
    _mockIsLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 200));

    _mockIsLoading = false;
    notifyListeners();
  }

  @override
  Future<void> fetchAllBookings() async {
    _mockIsLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 200));

    _mockIsLoading = false;
    notifyListeners();
  }

  @override
  List<BookingModel> get adminBookings => _bookings;

  @override
  List<BookingModel> getPendingBookings() {
    return _bookings.where((booking) => booking.status == 'pending').toList();
  }

  @override
  List<BookingModel> getAcceptedBookings() {
    return _bookings.where((booking) => booking.status == 'accepted').toList();
  }

  @override
  List<BookingModel> getCompletedBookings() {
    return _bookings.where((booking) => booking.status == 'completed').toList();
  }

  @override
  int getBookingCountByStatus(String status) {
    return _bookings.where((booking) => booking.status == status).length;
  }
}

class MockNotificationProvider extends NotificationProvider {
  final List<NotificationModel> _notifications = [
    TestHelpers.createTestNotification()
  ];
  bool _mockIsLoading = false;

  @override
  List<NotificationModel> get notifications => _notifications;

  @override
  bool get isLoading => _mockIsLoading;

  @override
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  @override
  Future<void> fetchNotifications({bool refresh = false}) async {
    _mockIsLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 200));

    _mockIsLoading = false;
    notifyListeners();
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index].isRead = true;
      notifyListeners();
    }
  }
}

class MockServiceProvider extends ServiceProvider {
  final List<ServiceModel> _services = [TestHelpers.createTestService()];
  bool _mockIsLoading = false;

  @override
  List<ServiceModel> get services => _services;

  @override
  bool get isLoading => _mockIsLoading;

  Future<void> fetchServices() async {
    _mockIsLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 200));

    _mockIsLoading = false;
    notifyListeners();
  }

  ServiceModel? getServiceByType(String serviceType) {
    try {
      return _services.firstWhere((service) => service.category == serviceType);
    } catch (e) {
      return null;
    }
  }
}

// Custom mock provider for testing error scenarios
class MockBookingProviderWithError extends MockBookingProvider {
  MockBookingProviderWithError() : super();

  @override
  Future<Map<String, dynamic>> createBooking(
      Map<String, dynamic> bookingData) async {
    _mockIsLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 100));

    _mockIsLoading = false;
    notifyListeners();

    throw Exception('Network error');
  }
}

// Custom mock provider for testing failure response scenarios
class MockBookingProviderWithFailure extends MockBookingProvider {
  MockBookingProviderWithFailure() : super();

  @override
  Future<Map<String, dynamic>> createBooking(
      Map<String, dynamic> bookingData) async {
    _mockIsLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 100));

    _mockIsLoading = false;
    notifyListeners();

    return {
      'success': false,
      'message': 'Failed to create booking. Please try again.',
    };
  }
}
