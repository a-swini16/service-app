import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:om_enterprises/screens/home_screen.dart';
import 'package:om_enterprises/screens/booking_form_screen.dart';
import 'package:om_enterprises/screens/user_booking_status_screen.dart';
import 'package:om_enterprises/screens/payment_method_selection_screen.dart';
import 'package:om_enterprises/providers/booking_provider.dart';
import 'package:om_enterprises/providers/auth_provider.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Complete Booking Workflow Integration Tests', () {
    testWidgets('should complete full booking creation workflow',
            (WidgetTester tester) async {
          final mockBookingProvider = MockBookingProvider();
          final mockAuthProvider = MockAuthProvider();

          await tester.pumpWidget(
            TestHelpers.createTestApp(
              child: HomeScreen(),
              bookingProvider: mockBookingProvider,
              authProvider: mockAuthProvider,
            ),
          );

          await tester.pumpAndSettle();

          // Step 1: Navigate to service selection
          final waterPurifierService = find.text('Water Purifier');
          expect(waterPurifierService, findsOneWidget);
          await tester.tap(waterPurifierService);
          await tester.pumpAndSettle();

          // Step 2: Fill booking form
          expect(find.byType(BookingFormScreen), findsOneWidget);

          await tester.enterText(
            find.widgetWithText(TextFormField, 'Customer Name'),
            'John Doe',
          );
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Phone Number'),
            '1234567890',
          );
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Address'),
            '123 Main Street, City, State 12345',
          );
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Description'),
            'Water purifier maintenance and filter replacement',
          );

          // Step 3: Submit booking
          final submitButton = find.text('Book Service');
          await tester.tap(submitButton);
          await tester.pumpAndSettle();

          // Step 4: Verify booking confirmation
          expect(find.text('Booking Confirmed'), findsOneWidget);
          expect(find.text('Your booking has been submitted successfully'),
              findsOneWidget);

          // Step 5: Navigate to booking status
          final viewBookingButton = find.text('View Booking Status');
          await tester.tap(viewBookingButton);
          await tester.pumpAndSettle();

          // Step 6: Verify booking appears in status screen
          expect(find.byType(UserBookingStatusScreen), findsOneWidget);
          expect(find.text('John Doe'), findsOneWidget);
          expect(find.text('pending'), findsOneWidget);
        });

    testWidgets('should handle booking status updates in real-time',
            (WidgetTester tester) async {
          final mockBookingProvider = MockBookingProvider();
          final testBooking = TestHelpers.createTestBooking();
          mockBookingProvider.clearBookings();
          mockBookingProvider.addBooking(testBooking);

          await tester.pumpWidget(
            TestHelpers.createTestApp(
              child: const UserBookingStatusScreen(),
              bookingProvider: mockBookingProvider,
            ),
          );

          await tester.pumpAndSettle();

          // Initial state - booking is pending
          expect(find.text('pending'), findsOneWidget);
          expect(find.byIcon(Icons.schedule), findsOneWidget);

          // Simulate status update to accepted
          final acceptedBooking = testBooking.copyWith(status: 'accepted');
          mockBookingProvider.clearBookings();
          mockBookingProvider.addBooking(acceptedBooking);
          await tester.pump();

          // Verify status updated
          expect(find.text('accepted'), findsOneWidget);
          expect(find.byIcon(Icons.check_circle), findsOneWidget);

          // Simulate status update to completed
          final completedBooking = acceptedBooking.copyWith(status: 'completed');
          mockBookingProvider.clearBookings();
          mockBookingProvider.addBooking(completedBooking);
          await tester.pump();

          // Verify final status
          expect(find.text('completed'), findsOneWidget);
          expect(find.byIcon(Icons.done_all), findsOneWidget);
        });

    testWidgets('should complete payment workflow after service completion',
            (WidgetTester tester) async {
          final mockBookingProvider = MockBookingProvider();
          final completedBooking = TestHelpers.createTestBooking().copyWith(
            status: 'completed',
            paymentAmount: 500.0,
          );

          mockBookingProvider.clearBookings();
          mockBookingProvider.addBooking(completedBooking);

          await tester.pumpWidget(
            TestHelpers.createTestApp(
              child: const UserBookingStatusScreen(),
              bookingProvider: mockBookingProvider,
            ),
          );

          await tester.pumpAndSettle();

          // Step 1: Find completed booking with payment button
          expect(find.text('completed'), findsOneWidget);
          final payButton = find.text('Pay Now');
          expect(payButton, findsOneWidget);

          // Step 2: Navigate to payment screen
          await tester.tap(payButton);
          await tester.pumpAndSettle();

          // Step 3: Verify payment method selection screen
          expect(find.byType(PaymentMethodSelectionScreen), findsOneWidget);
          expect(find.text('₹500.00'), findsOneWidget);

          // Step 4: Select payment method
          await tester.tap(find.text('Online Payment'));
          await tester.pump();

          // Step 5: Proceed to payment
          final proceedButton = find.text('Proceed to Payment');
          await tester.tap(proceedButton);
          await tester.pumpAndSettle();

          // Step 6: Verify payment processing
          expect(find.text('Processing Payment...'), findsOneWidget);
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
        });

    testWidgets('should handle network errors gracefully during booking',
            (WidgetTester tester) async {
          final mockBookingProvider = MockBookingProviderWithError();

          await tester.pumpWidget(
            TestHelpers.createTestApp(
              child: const BookingFormScreen(serviceType: 'water_purifier'),
              bookingProvider: mockBookingProvider,
            ),
          );

          // Fill and submit form
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Customer Name'),
            'John Doe',
          );
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Phone Number'),
            '1234567890',
          );
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Address'),
            '123 Main Street',
          );

          final submitButton = find.text('Book Service');
          await tester.tap(submitButton);
          await tester.pumpAndSettle();

          // Verify error handling
          expect(find.text('Network error occurred'), findsOneWidget);
          expect(find.text('Retry'), findsOneWidget);
        });

    testWidgets('should maintain booking data across app restarts',
            (WidgetTester tester) async {
          final mockBookingProvider = MockBookingProvider();
          final testBooking = TestHelpers.createTestBooking();
          mockBookingProvider.addBooking(testBooking);

          // First app session
          await tester.pumpWidget(
            TestHelpers.createTestApp(
              child: const UserBookingStatusScreen(),
              bookingProvider: mockBookingProvider,
            ),
          );

          await tester.pumpAndSettle();
          expect(find.text('Test Customer'), findsOneWidget);

          // Simulate app restart by creating new widget tree
          await tester.pumpWidget(
            TestHelpers.createTestApp(
              child: const UserBookingStatusScreen(),
              bookingProvider: mockBookingProvider,
            ),
          );

          await tester.pumpAndSettle();

          // Verify data persisted
          expect(find.text('Test Customer'), findsOneWidget);
          expect(find.text('pending'), findsOneWidget);
        });

    testWidgets('should handle multiple concurrent bookings',
            (WidgetTester tester) async {
          final mockBookingProvider = MockBookingProvider();

          // Add multiple bookings
          for (int i = 0; i < 5; i++) {
            final booking = TestHelpers.createTestBooking().copyWith(
              id: 'booking-$i',
              customerName: 'Customer $i',
            );
            mockBookingProvider.addBooking(booking);
          }

          await tester.pumpWidget(
            TestHelpers.createTestApp(
              child: const UserBookingStatusScreen(),
              bookingProvider: mockBookingProvider,
            ),
          );

          await tester.pumpAndSettle();

          // Verify all bookings are displayed
          for (int i = 0; i < 5; i++) {
            expect(find.text('Customer $i'), findsOneWidget);
          }

          // Verify list is scrollable
          expect(find.byType(ListView), findsOneWidget);
        });

    testWidgets('should validate form data before submission',
            (WidgetTester tester) async {
          await tester.pumpWidget(
            TestHelpers.createTestApp(
              child: const BookingFormScreen(serviceType: 'water_purifier'),
            ),
          );

          // Try to submit empty form
          final submitButton = find.text('Book Service');
          await tester.tap(submitButton);
          await tester.pump();

          // Verify validation errors
          expect(find.text('Please enter customer name'), findsOneWidget);
          expect(find.text('Please enter phone number'), findsOneWidget);
          expect(find.text('Please enter address'), findsOneWidget);

          // Fill partial data
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Customer Name'),
            'John',
          );
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Phone Number'),
            '123', // Invalid phone
          );

          await tester.tap(submitButton);
          await tester.pump();

          // Verify specific validation errors
          expect(find.text('Please enter a valid 10-digit phone number'),
              findsOneWidget);
          expect(find.text('Please enter address'), findsOneWidget);
        });

    testWidgets('should show booking confirmation with correct details',
            (WidgetTester tester) async {
          final mockBookingProvider = MockBookingProvider();

          await tester.pumpWidget(
            TestHelpers.createTestApp(
              child: const BookingFormScreen(serviceType: 'ac_repair'),
              bookingProvider: mockBookingProvider,
            ),
          );

          // Fill form with specific data
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Customer Name'),
            'Jane Smith',
          );
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Phone Number'),
            '9876543210',
          );
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Address'),
            '456 Oak Avenue, Downtown',
          );
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Description'),
            'AC not cooling properly, needs inspection',
          );

          // Submit form
          final submitButton = find.text('Book Service');
          await tester.tap(submitButton);
          await tester.pumpAndSettle();

          // Verify confirmation shows correct details
          expect(find.text('Booking Confirmed'), findsOneWidget);
          expect(find.text('Jane Smith'), findsOneWidget);
          expect(find.text('AC Repair Service'), findsOneWidget);
          expect(find.text('9876543210'), findsOneWidget);
        });
  });
}
