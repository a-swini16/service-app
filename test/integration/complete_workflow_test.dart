import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:om_enterprises/main.dart';
import '../helpers/integration_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Complete Workflow Integration Tests', () {
    late IntegrationTestHelpers testHelpers;

    setUpAll(() async {
      testHelpers = IntegrationTestHelpers();
      await testHelpers.setupTestEnvironment();
    });

    tearDownAll(() async {
      await testHelpers.cleanupTestEnvironment();
    });

    testWidgets('Complete User Journey: Booking Creation to Payment', (WidgetTester tester) async {
      // Launch the app
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Step 1: User Login
      await testHelpers.performUserLogin(tester);
      await tester.pumpAndSettle();

      // Verify home screen is displayed
      expect(find.text('Home'), findsOneWidget);

      // Step 2: Navigate to booking creation
      await tester.tap(find.text('Water Purifier Service'));
      await tester.pumpAndSettle();

      // Step 3: Fill booking form
      await testHelpers.fillBookingForm(tester, {
        'customerName': 'Test User',
        'customerPhone': '1234567890',
        'customerAddress': '123 Test Street, Test City',
        'description': 'Water purifier maintenance required',
        'preferredDate': DateTime.now().add(Duration(days: 1)),
        'preferredTime': '10:00 AM'
      });

      // Step 4: Submit booking
      await tester.tap(find.text('Confirm Booking'));
      await tester.pumpAndSettle();

      // Verify booking confirmation screen
      expect(find.text('Booking Confirmed'), findsOneWidget);
      expect(find.textContaining('Booking ID:'), findsOneWidget);

      // Step 5: Navigate to booking status
      await tester.tap(find.text('View Status'));
      await tester.pumpAndSettle();

      // Verify initial booking status
      expect(find.text('Pending'), findsOneWidget);

      // Step 6: Simulate admin acceptance (via API call)
      final bookingId = await testHelpers.getLatestBookingId();
      await testHelpers.simulateAdminAction(bookingId, 'accept');
      
      // Refresh the status screen
      await tester.drag(find.byType(RefreshIndicator), Offset(0, 300));
      await tester.pumpAndSettle();

      // Verify status updated to confirmed
      expect(find.text('Confirmed'), findsOneWidget);

      // Step 7: Simulate worker assignment
      await testHelpers.simulateWorkerAssignment(bookingId);
      
      // Refresh and verify worker assigned status
      await tester.drag(find.byType(RefreshIndicator), Offset(0, 300));
      await tester.pumpAndSettle();
      expect(find.text('Worker Assigned'), findsOneWidget);

      // Step 8: Simulate service completion
      await testHelpers.simulateServiceCompletion(bookingId);
      
      // Refresh and verify completion
      await tester.drag(find.byType(RefreshIndicator), Offset(0, 300));
      await tester.pumpAndSettle();
      expect(find.text('Service Completed'), findsOneWidget);

      // Step 9: Navigate to payment
      await tester.tap(find.text('Pay Now'));
      await tester.pumpAndSettle();

      // Verify payment screen
      expect(find.text('Payment'), findsOneWidget);
      expect(find.text('Select Payment Method'), findsOneWidget);

      // Step 10: Complete payment
      await tester.tap(find.text('Online Payment'));
      await tester.pumpAndSettle();

      await testHelpers.fillPaymentForm(tester);
      await tester.tap(find.text('Pay Now'));
      await tester.pumpAndSettle();

      // Step 11: Verify payment success
      expect(find.text('Payment Successful'), findsOneWidget);
      expect(find.text('Thank you for your payment'), findsOneWidget);

      // Step 12: Verify final booking status
      await tester.tap(find.text('View Booking'));
      await tester.pumpAndSettle();
      expect(find.text('Paid'), findsOneWidget);
    });

    testWidgets('Admin Workflow: Notification to Service Completion', (WidgetTester tester) async {
      // Launch the app
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      // Step 1: Admin Login
      await testHelpers.performAdminLogin(tester);
      await tester.pumpAndSettle();

      // Step 2: Create a test booking (simulate user booking)
      await testHelpers.createTestBooking();

      // Step 3: Navigate to admin dashboard
      await tester.tap(find.text('Admin Panel'));
      await tester.pumpAndSettle();

      // Verify admin dashboard
      expect(find.text('Admin Dashboard'), findsOneWidget);
      expect(find.text('Pending Bookings'), findsOneWidget);

      // Step 4: Check for new booking notification
      await tester.tap(find.byIcon(Icons.notifications));
      await tester.pumpAndSettle();

      expect(find.textContaining('New booking request'), findsOneWidget);

      // Step 5: Navigate back and view booking details
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Find and tap on the test booking
      await tester.tap(find.textContaining('Test User'));
      await tester.pumpAndSettle();

      // Verify booking details screen
      expect(find.text('Booking Details'), findsOneWidget);
      expect(find.text('Test User'), findsOneWidget);

      // Step 6: Accept the booking
      await tester.tap(find.text('Accept Booking'));
      await tester.pumpAndSettle();

      // Verify acceptance confirmation
      expect(find.text('Booking Accepted'), findsOneWidget);

      // Step 7: Assign worker
      await tester.tap(find.text('Assign Worker'));
      await tester.pumpAndSettle();

      // Select a worker
      await tester.tap(find.text('John Doe'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm Assignment'));
      await tester.pumpAndSettle();

      // Verify worker assignment
      expect(find.text('Worker Assigned Successfully'), findsOneWidget);

      // Step 8: Mark service as completed
      await tester.tap(find.text('Mark as Completed'));
      await tester.pumpAndSettle();

      // Confirm completion
      await tester.tap(find.text('Confirm Completion'));
      await tester.pumpAndSettle();

      // Verify completion
      expect(find.text('Service Marked as Completed'), findsOneWidget);

      // Step 9: Verify booking status updated
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Refresh dashboard
      await tester.drag(find.byType(RefreshIndicator), Offset(0, 300));
      await tester.pumpAndSettle();

      // Verify booking moved to completed section
      expect(find.text('Completed Bookings'), findsOneWidget);
    });

    testWidgets('Notification Triggers and Delivery Validation', (WidgetTester tester) async {
      // Launch the app
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      // Step 1: User Login
      await testHelpers.performUserLogin(tester);
      await tester.pumpAndSettle();

      // Step 2: Create booking and track notifications
      final bookingId = await testHelpers.createTestBookingWithNotificationTracking();

      // Step 3: Verify booking creation notification sent to admin
      final adminNotifications = await testHelpers.getAdminNotifications();
      expect(adminNotifications.any((n) => n['type'] == 'booking_created'), true);

      // Step 4: Simulate admin acceptance and verify user notification
      await testHelpers.simulateAdminAction(bookingId, 'accept');
      
      // Wait for notification processing
      await tester.pump(Duration(seconds: 2));

      final userNotifications = await testHelpers.getUserNotifications();
      expect(userNotifications.any((n) => n['type'] == 'booking_accepted'), true);

      // Step 5: Check in-app notification display
      await tester.tap(find.byIcon(Icons.notifications));
      await tester.pumpAndSettle();

      expect(find.textContaining('Your booking has been accepted'), findsOneWidget);

      // Step 6: Simulate worker assignment notification
      await testHelpers.simulateWorkerAssignment(bookingId);
      await tester.pump(Duration(seconds: 2));

      // Refresh notifications
      await tester.drag(find.byType(RefreshIndicator), Offset(0, 300));
      await tester.pumpAndSettle();

      expect(find.textContaining('Worker has been assigned'), findsOneWidget);

      // Step 7: Simulate service completion notification
      await testHelpers.simulateServiceCompletion(bookingId);
      await tester.pump(Duration(seconds: 2));

      // Refresh notifications
      await tester.drag(find.byType(RefreshIndicator), Offset(0, 300));
      await tester.pumpAndSettle();

      expect(find.textContaining('Service has been completed'), findsOneWidget);

      // Step 8: Verify payment notification after completion
      final paymentNotifications = await testHelpers.getUserNotifications();
      expect(paymentNotifications.any((n) => n['type'] == 'payment_required'), true);

      // Step 9: Complete payment and verify final notifications
      await testHelpers.simulatePaymentCompletion(bookingId);
      await tester.pump(Duration(seconds: 2));

      final finalNotifications = await testHelpers.getAdminNotifications();
      expect(finalNotifications.any((n) => n['type'] == 'payment_received'), true);
    });

    testWidgets('Error Handling and Recovery Scenarios', (WidgetTester tester) async {
      // Launch the app
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      // Step 1: Test network failure during booking creation
      await testHelpers.performUserLogin(tester);
      await tester.pumpAndSettle();

      // Simulate network failure
      await testHelpers.simulateNetworkFailure();

      // Try to create booking
      await tester.tap(find.text('Water Purifier Service'));
      await tester.pumpAndSettle();

      await testHelpers.fillBookingForm(tester, {
        'customerName': 'Test User',
        'customerPhone': '1234567890',
        'customerAddress': '123 Test Street',
        'description': 'Test booking',
      });

      await tester.tap(find.text('Confirm Booking'));
      await tester.pumpAndSettle();

      // Verify error handling
      expect(find.textContaining('Network error'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Step 2: Test recovery after network restoration
      await testHelpers.restoreNetwork();

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // Verify successful booking creation
      expect(find.text('Booking Confirmed'), findsOneWidget);

      // Step 3: Test offline data persistence
      await testHelpers.simulateOfflineMode();

      // Navigate to booking status
      await tester.tap(find.text('View Status'));
      await tester.pumpAndSettle();

      // Verify offline data display
      expect(find.text('Offline Mode'), findsOneWidget);
      expect(find.textContaining('Last updated'), findsOneWidget);

      // Step 4: Test data sync after coming online
      await testHelpers.restoreOnlineMode();
      
      // Trigger sync
      await tester.drag(find.byType(RefreshIndicator), Offset(0, 300));
      await tester.pumpAndSettle();

      // Verify data synchronization
      expect(find.text('Data synchronized'), findsOneWidget);
    });

    testWidgets('Real-time Updates and WebSocket Communication', (WidgetTester tester) async {
      // Launch the app
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      // Step 1: User Login
      await testHelpers.performUserLogin(tester);
      await tester.pumpAndSettle();

      // Step 2: Navigate to booking status screen
      await tester.tap(find.text('My Bookings'));
      await tester.pumpAndSettle();

      // Step 3: Create a booking and verify real-time status updates
      final bookingId = await testHelpers.createTestBooking();

      // Wait for WebSocket connection
      await tester.pump(Duration(seconds: 1));

      // Step 4: Simulate admin action and verify real-time update
      await testHelpers.simulateAdminActionWithWebSocket(bookingId, 'accept');

      // Wait for WebSocket message
      await tester.pump(Duration(seconds: 2));

      // Verify real-time status update without manual refresh
      expect(find.text('Confirmed'), findsOneWidget);

      // Step 5: Test real-time notification delivery
      await testHelpers.simulateWorkerAssignmentWithWebSocket(bookingId);
      await tester.pump(Duration(seconds: 2));

      // Verify real-time notification
      expect(find.byIcon(Icons.notifications_active), findsOneWidget);

      // Step 6: Test WebSocket reconnection
      await testHelpers.simulateWebSocketDisconnection();
      await tester.pump(Duration(seconds: 3));

      // Verify reconnection indicator
      expect(find.text('Reconnecting...'), findsOneWidget);

      await testHelpers.restoreWebSocketConnection();
      await tester.pump(Duration(seconds: 2));

      // Verify successful reconnection
      expect(find.text('Connected'), findsOneWidget);
    });
  });
}