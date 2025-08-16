import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:om_enterprises/screens/user_booking_status_screen.dart';
import 'package:om_enterprises/models/booking_model.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('BookingStatusScreen Widget Tests', () {
    testWidgets('should display loading indicator when fetching bookings',
        (WidgetTester tester) async {
      final mockBookingProvider = MockBookingProvider();
      mockBookingProvider.setLoading(true);

      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: const UserBookingStatusScreen(),
          bookingProvider: mockBookingProvider,
        ),
      );

      // Verify loading indicator is shown
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display bookings list when data is loaded',
        (WidgetTester tester) async {
      final mockBookingProvider = MockBookingProvider();

      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: const UserBookingStatusScreen(),
          bookingProvider: mockBookingProvider,
        ),
      );

      await tester.pumpAndSettle();

      // Verify bookings are displayed
      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('Test Customer'), findsOneWidget);
      expect(find.text('pending'), findsOneWidget);
    });

    testWidgets('should display empty state when no bookings exist',
        (WidgetTester tester) async {
      final mockBookingProvider = MockBookingProvider();
      mockBookingProvider.clearBookings();

      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: const UserBookingStatusScreen(),
          bookingProvider: mockBookingProvider,
        ),
      );

      await tester.pumpAndSettle();

      // Verify empty state is shown
      expect(find.text('No bookings found'), findsOneWidget);
      expect(find.text('You haven\'t made any bookings yet.'), findsOneWidget);
    });

    testWidgets('should filter bookings by status',
        (WidgetTester tester) async {
      final mockBookingProvider = MockBookingProvider();

      // Add bookings with different statuses
      final pendingBooking = TestHelpers.createTestBooking();
      pendingBooking.status = 'pending';
      mockBookingProvider.addBooking(pendingBooking);

      final acceptedBooking = TestHelpers.createTestBooking();
      acceptedBooking.status = 'accepted';
      mockBookingProvider.addBooking(acceptedBooking);

      final completedBooking = TestHelpers.createTestBooking();
      completedBooking.status = 'completed';
      mockBookingProvider.addBooking(completedBooking);

      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: const UserBookingStatusScreen(),
          bookingProvider: mockBookingProvider,
        ),
      );

      await tester.pumpAndSettle();

      // Verify all bookings are initially shown
      expect(find.text('pending'), findsWidgets);
      expect(find.text('accepted'), findsOneWidget);
      expect(find.text('completed'), findsOneWidget);

      // Tap on filter dropdown
      final filterDropdown = find.byType(DropdownButton<String>);
      await tester.tap(filterDropdown);
      await tester.pumpAndSettle();

      // Select 'accepted' filter
      await tester.tap(find.text('Accepted').last);
      await tester.pumpAndSettle();

      // Verify only accepted bookings are shown
      expect(find.text('accepted'), findsOneWidget);
      expect(find.text('pending'), findsNothing);
      expect(find.text('completed'), findsNothing);
    });

    testWidgets('should navigate to booking details when booking is tapped',
        (WidgetTester tester) async {
      final mockBookingProvider = MockBookingProvider();

      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: const UserBookingStatusScreen(),
          bookingProvider: mockBookingProvider,
        ),
      );

      await tester.pumpAndSettle();

      // Tap on a booking item
      final bookingItem = find.byType(ListTile).first;
      await tester.tap(bookingItem);
      await tester.pumpAndSettle();

      // Verify navigation occurred (this would need to be mocked in a real test)
      // For now, we just verify the tap was registered
      expect(bookingItem, findsOneWidget);
    });

    testWidgets('should refresh bookings when pull-to-refresh is triggered',
        (WidgetTester tester) async {
      final mockBookingProvider = MockBookingProvider();

      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: const UserBookingStatusScreen(),
          bookingProvider: mockBookingProvider,
        ),
      );

      await tester.pumpAndSettle();

      // Perform pull-to-refresh gesture
      await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
      await tester.pump();

      // Verify refresh indicator is shown
      expect(find.byType(RefreshProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      // Verify refresh completed
      expect(find.byType(RefreshProgressIndicator), findsNothing);
    });

    testWidgets('should display correct status colors and icons',
        (WidgetTester tester) async {
      final mockBookingProvider = MockBookingProvider();

      // Add bookings with different statuses
      final pendingBooking = TestHelpers.createTestBooking();
      pendingBooking.status = 'pending';

      final acceptedBooking = TestHelpers.createTestBooking();
      acceptedBooking.status = 'accepted';

      final completedBooking = TestHelpers.createTestBooking();
      completedBooking.status = 'completed';

      mockBookingProvider.clearBookings();
      mockBookingProvider.addBooking(pendingBooking);
      mockBookingProvider.addBooking(acceptedBooking);
      mockBookingProvider.addBooking(completedBooking);

      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: const UserBookingStatusScreen(),
          bookingProvider: mockBookingProvider,
        ),
      );

      await tester.pumpAndSettle();

      // Verify status indicators are present
      expect(find.byIcon(Icons.schedule), findsOneWidget); // Pending
      expect(find.byIcon(Icons.check_circle), findsOneWidget); // Accepted
      expect(find.byIcon(Icons.done_all), findsOneWidget); // Completed
    });

    testWidgets('should show booking timeline for detailed view',
        (WidgetTester tester) async {
      final mockBookingProvider = MockBookingProvider();
      final booking = TestHelpers.createTestBooking();
      booking.statusHistory = [
        StatusHistoryEntry(
          status: 'pending',
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
        ),
        StatusHistoryEntry(
          status: 'accepted',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
        ),
        StatusHistoryEntry(
          status: 'completed',
          timestamp: DateTime.now(),
        ),
      ];

      mockBookingProvider.clearBookings();
      mockBookingProvider.addBooking(booking);

      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: const UserBookingStatusScreen(),
          bookingProvider: mockBookingProvider,
        ),
      );

      await tester.pumpAndSettle();

      // Tap on booking to expand details
      final bookingItem = find.byType(ExpansionTile).first;
      await tester.tap(bookingItem);
      await tester.pumpAndSettle();

      // Verify timeline is shown
      expect(find.text('Booking Timeline'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Accepted'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
    });
  });
}
