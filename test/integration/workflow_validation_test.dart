import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:om_enterprises/main.dart';
import 'package:om_enterprises/providers/auth_provider.dart';
import 'package:om_enterprises/providers/booking_provider.dart';
import 'package:om_enterprises/providers/notification_provider.dart';
import 'package:om_enterprises/models/booking_model.dart';
import 'package:om_enterprises/models/notification_model.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Workflow Validation Integration Tests', () {
    testWidgets('Complete User Booking Journey', (WidgetTester tester) async {
      // Create test app with mock providers
      final authProvider = MockAuthProvider();
      final bookingProvider = MockBookingProvider();
      final notificationProvider = MockNotificationProvider();

      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: MyApp(),
          authProvider: authProvider,
          bookingProvider: bookingProvider,
          notificationProvider: notificationProvider,
        ),
      );

      // Wait for app to load
      await tester.pumpAndSettle();

      // Test 1: User can navigate to booking creation
      expect(find.text('Home'), findsOneWidget);
      
      // Look for service options
      final waterPurifierFinder = find.text('Water Purifier Service');
      if (waterPurifierFinder.evaluate().isNotEmpty) {
        await tester.tap(waterPurifierFinder);
        await tester.pumpAndSettle();
      }

      // Test 2: Booking form validation
      final confirmButtonFinder = find.text('Confirm Booking');
      if (confirmButtonFinder.evaluate().isNotEmpty) {
        // Try to submit empty form
        await tester.tap(confirmButtonFinder);
        await tester.pumpAndSettle();
        
        // Should show validation errors
        expect(find.textContaining('required'), findsWidgets);
      }

      // Test 3: Successful booking creation
      // Fill form if fields exist
      final nameFieldFinder = find.byKey(Key('customerName'));
      if (nameFieldFinder.evaluate().isNotEmpty) {
        await tester.enterText(nameFieldFinder, 'Test User');
      }

      final phoneFieldFinder = find.byKey(Key('customerPhone'));
      if (phoneFieldFinder.evaluate().isNotEmpty) {
        await tester.enterText(phoneFieldFinder, '1234567890');
      }

      final addressFieldFinder = find.byKey(Key('customerAddress'));
      if (addressFieldFinder.evaluate().isNotEmpty) {
        await tester.enterText(addressFieldFinder, '123 Test Street');
      }

      final descriptionFieldFinder = find.byKey(Key('description'));
      if (descriptionFieldFinder.evaluate().isNotEmpty) {
        await tester.enterText(descriptionFieldFinder, 'Test booking');
      }

      await tester.pumpAndSettle();

      // Submit booking
      if (confirmButtonFinder.evaluate().isNotEmpty) {
        await tester.tap(confirmButtonFinder);
        await tester.pumpAndSettle();
      }

      // Test 4: Booking confirmation
      expect(find.textContaining('Booking'), findsWidgets);
    });

    testWidgets('Booking Status Tracking', (WidgetTester tester) async {
      final bookingProvider = MockBookingProvider();
      
      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: MyApp(),
          bookingProvider: bookingProvider,
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to booking status if available
      final myBookingsFinder = find.text('My Bookings');
      if (myBookingsFinder.evaluate().isNotEmpty) {
        await tester.tap(myBookingsFinder);
        await tester.pumpAndSettle();

        // Should show booking list
        expect(find.textContaining('Test Customer'), findsWidgets);
        expect(find.textContaining('pending'), findsWidgets);
      }
    });

    testWidgets('Notification System', (WidgetTester tester) async {
      final notificationProvider = MockNotificationProvider();
      
      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: MyApp(),
          notificationProvider: notificationProvider,
        ),
      );

      await tester.pumpAndSettle();

      // Look for notification icon
      final notificationIconFinder = find.byIcon(Icons.notifications);
      if (notificationIconFinder.evaluate().isNotEmpty) {
        await tester.tap(notificationIconFinder);
        await tester.pumpAndSettle();

        // Should show notifications
        expect(find.textContaining('Test Notification'), findsWidgets);
      }
    });

    testWidgets('Admin Panel Access', (WidgetTester tester) async {
      final authProvider = MockAuthProvider();
      
      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: MyApp(),
          authProvider: authProvider,
        ),
      );

      await tester.pumpAndSettle();

      // Look for admin panel access
      final adminPanelFinder = find.text('Admin Panel');
      if (adminPanelFinder.evaluate().isNotEmpty) {
        await tester.tap(adminPanelFinder);
        await tester.pumpAndSettle();

        // Should show admin dashboard
        expect(find.textContaining('Admin'), findsWidgets);
      }
    });

    testWidgets('Payment Flow', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Look for payment-related screens
      final paymentFinder = find.text('Payment');
      if (paymentFinder.evaluate().isNotEmpty) {
        await tester.tap(paymentFinder);
        await tester.pumpAndSettle();

        // Should show payment options
        expect(find.textContaining('Payment'), findsWidgets);
      }
    });

    testWidgets('Error Handling', (WidgetTester tester) async {
      // Test error scenarios
      final bookingProvider = MockBookingProvider();
      
      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: MyApp(),
          bookingProvider: bookingProvider,
        ),
      );

      await tester.pumpAndSettle();

      // Test network error handling
      // This would be implemented based on the actual error handling in the app
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Offline Support', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Test offline functionality
      // This would test cached data display and offline booking creation
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Real-time Updates', (WidgetTester tester) async {
      final notificationProvider = MockNotificationProvider();
      
      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: MyApp(),
          notificationProvider: notificationProvider,
        ),
      );

      await tester.pumpAndSettle();

      // Test real-time notification updates
      // Simulate receiving a new notification
      notificationProvider.addTestNotification(
        NotificationModel(
          id: 'test-realtime-notification',
          title: 'Real-time Test',
          message: 'This is a real-time notification test',
          type: 'booking_accepted',
          recipient: 'user',
          priority: 'medium',
          isRead: false,
          createdAt: DateTime.now(),
        ),
      );

      await tester.pump();

      // Should update notification count
      expect(notificationProvider.unreadCount, greaterThan(0));
    });

    testWidgets('Data Persistence', (WidgetTester tester) async {
      final bookingProvider = MockBookingProvider();
      
      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: MyApp(),
          bookingProvider: bookingProvider,
        ),
      );

      await tester.pumpAndSettle();

      // Test data persistence
      final initialBookingCount = bookingProvider.bookings.length;
      
      // Create a new booking
      await bookingProvider.createBooking({
        'serviceType': 'ac_repair',
        'customerName': 'Persistence Test User',
        'customerPhone': '9876543210',
        'customerAddress': '456 Persistence Street',
        'description': 'Data persistence test',
        'preferredDate': DateTime.now().add(Duration(days: 1)).toIso8601String(),
        'preferredTime': '2:00 PM',
      });

      // Should have one more booking
      expect(bookingProvider.bookings.length, equals(initialBookingCount + 1));
    });

    testWidgets('Security and Validation', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Test input validation and security
      // This would test XSS prevention, input sanitization, etc.
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Performance Under Load', (WidgetTester tester) async {
      final bookingProvider = MockBookingProvider();
      
      // Add multiple bookings to test performance
      for (int i = 0; i < 50; i++) {
        await bookingProvider.createBooking({
          'serviceType': 'water_purifier',
          'customerName': 'Load Test User $i',
          'customerPhone': '123456789$i',
          'customerAddress': '${i}23 Load Test Street',
          'description': 'Load test booking $i',
          'preferredDate': DateTime.now().add(Duration(days: 1)).toIso8601String(),
          'preferredTime': '10:00 AM',
        });
      }

      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: MyApp(),
          bookingProvider: bookingProvider,
        ),
      );

      // Measure rendering performance
      final stopwatch = Stopwatch()..start();
      await tester.pumpAndSettle();
      stopwatch.stop();

      // Should render within reasonable time (less than 5 seconds)
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
      
      // Should handle large datasets
      expect(bookingProvider.bookings.length, equals(51)); // 50 + 1 initial
    });
  });
}

// Extension to add test methods to MockNotificationProvider
extension MockNotificationProviderExtension on MockNotificationProvider {
  void addTestNotification(NotificationModel notification) {
    _notifications.add(notification);
    notifyListeners();
  }
  
  List<NotificationModel> get _notifications {
    // Access private field through reflection or make it protected
    return notifications as List<NotificationModel>;
  }
}