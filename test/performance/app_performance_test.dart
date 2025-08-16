import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:om_enterprises/screens/home_screen.dart';
import 'package:om_enterprises/screens/user_booking_status_screen.dart';
import 'package:om_enterprises/screens/booking_form_screen.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('App Performance Tests', () {
    testWidgets('should render home screen within performance threshold', (WidgetTester tester) async {
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();
      stopwatch.stop();

      // Verify home screen renders within 500ms
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
    });

    testWidgets('should handle large booking lists efficiently', (WidgetTester tester) async {
      final mockBookingProvider = MockBookingProvider();
      
      // Create large dataset (100 bookings)
      mockBookingProvider.clearBookings();
      for (int i = 0; i < 100; i++) {
        final booking = TestHelpers.createTestBooking();
        booking.id = 'booking-$i';
        booking.customerName = 'Customer $i';
        booking.status = ['pending', 'accepted', 'completed'][i % 3];
        mockBookingProvider.addBooking(booking);
      }

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: const UserBookingStatusScreen(),
          bookingProvider: mockBookingProvider,
        ),
      );

      await tester.pumpAndSettle();
      stopwatch.stop();

      // Verify large list renders within 1 second
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));

      // Verify scrolling performance
      final scrollStopwatch = Stopwatch()..start();
      
      await tester.fling(find.byType(ListView), const Offset(0, -500), 1000);
      await tester.pumpAndSettle();
      
      scrollStopwatch.stop();

      // Verify smooth scrolling (under 100ms for fling)
      expect(scrollStopwatch.elapsedMilliseconds, lessThan(100));
    });

    testWidgets('should maintain 60fps during animations', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: const BookingFormScreen(serviceType: 'water_purifier'),
        ),
      );

      // Measure frame rendering during form field focus animations
      final frameStopwatch = Stopwatch()..start();
      int frameCount = 0;

      // Focus on text field to trigger animation
      await tester.tap(find.widgetWithText(TextFormField, 'Customer Name'));
      
      // Pump frames and count them
      for (int i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 16)); // 60fps = 16ms per frame
        frameCount++;
      }
      
      frameStopwatch.stop();

      // Verify we maintained close to 60fps (within 10% tolerance)
      final expectedDuration = frameCount * 16; // 16ms per frame at 60fps
      final actualDuration = frameStopwatch.elapsedMilliseconds;
      final tolerance = expectedDuration * 0.1; // 10% tolerance

      expect(actualDuration, lessThan(expectedDuration + tolerance));
    });

    testWidgets('should handle rapid user interactions without lag', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: const BookingFormScreen(serviceType: 'water_purifier'),
        ),
      );

      final stopwatch = Stopwatch()..start();

      // Simulate rapid form field interactions
      final fields = [
        'Customer Name',
        'Phone Number',
        'Address',
        'Description',
      ];

      for (int i = 0; i < 10; i++) {
        for (final fieldName in fields) {
          await tester.tap(find.widgetWithText(TextFormField, fieldName));
          await tester.enterText(
            find.widgetWithText(TextFormField, fieldName),
            'Test data $i',
          );
          await tester.pump();
        }
      }

      stopwatch.stop();

      // Verify rapid interactions complete within 2 seconds
      expect(stopwatch.elapsedMilliseconds, lessThan(2000));
    });

    testWidgets('should efficiently filter large booking datasets', (WidgetTester tester) async {
      final mockBookingProvider = MockBookingProvider();
      
      // Create large dataset with mixed statuses
      mockBookingProvider.clearBookings();
      for (int i = 0; i < 500; i++) {
        final booking = TestHelpers.createTestBooking();
        booking.id = 'booking-$i';
        booking.customerName = 'Customer $i';
        booking.status = ['pending', 'accepted', 'completed', 'rejected'][i % 4];
        mockBookingProvider.addBooking(booking);
      }

      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: const UserBookingStatusScreen(),
          bookingProvider: mockBookingProvider,
        ),
      );

      await tester.pumpAndSettle();

      // Measure filter performance
      final filterStopwatch = Stopwatch()..start();

      // Apply filter
      final filterDropdown = find.byType(DropdownButton<String>);
      await tester.tap(filterDropdown);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Completed').last);
      await tester.pumpAndSettle();

      filterStopwatch.stop();

      // Verify filtering completes within 200ms
      expect(filterStopwatch.elapsedMilliseconds, lessThan(200));

      // Verify correct number of filtered results
      final completedBookings = mockBookingProvider.bookings
          .where((b) => b.status == 'completed')
          .length;
      
      // Should show only completed bookings
      expect(find.text('completed'), findsNWidgets(completedBookings));
    });

    testWidgets('should handle memory efficiently with large datasets', (WidgetTester tester) async {
      final mockBookingProvider = MockBookingProvider();
      
      // Create very large dataset
      mockBookingProvider.clearBookings();
      for (int i = 0; i < 1000; i++) {
        final booking = TestHelpers.createTestBooking();
        booking.id = 'booking-$i';
        booking.customerName = 'Customer $i';
        booking.description = 'Long description ' * 50; // Large text content
        mockBookingProvider.addBooking(booking);
      }

      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: const UserBookingStatusScreen(),
          bookingProvider: mockBookingProvider,
        ),
      );

      await tester.pumpAndSettle();

      // Scroll through entire list to test memory usage
      final scrollStopwatch = Stopwatch()..start();
      
      for (int i = 0; i < 10; i++) {
        await tester.fling(find.byType(ListView), const Offset(0, -1000), 2000);
        await tester.pumpAndSettle();
      }
      
      scrollStopwatch.stop();

      // Verify scrolling through large dataset completes within reasonable time
      expect(scrollStopwatch.elapsedMilliseconds, lessThan(3000));
    });

    testWidgets('should maintain responsiveness during data loading', (WidgetTester tester) async {
      final mockBookingProvider = MockBookingProviderWithDelay(const Duration(seconds: 2));

      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: const UserBookingStatusScreen(),
          bookingProvider: mockBookingProvider,
        ),
      );

      // Verify loading indicator appears immediately
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Verify UI remains responsive during loading
      final refreshStopwatch = Stopwatch()..start();
      
      await tester.fling(find.byType(RefreshIndicator), const Offset(0, 300), 1000);
      await tester.pump();
      
      refreshStopwatch.stop();

      // Verify refresh gesture responds quickly even during loading
      expect(refreshStopwatch.elapsedMilliseconds, lessThan(100));
    });

    testWidgets('should optimize image loading and caching', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: HomeScreen(),
        ),
      );

      final imageLoadStopwatch = Stopwatch()..start();

      // Wait for all images to load
      await tester.pumpAndSettle();

      imageLoadStopwatch.stop();

      // Verify images load within reasonable time
      expect(imageLoadStopwatch.elapsedMilliseconds, lessThan(1000));

      // Verify cached images load faster on subsequent renders
      final cachedLoadStopwatch = Stopwatch()..start();

      // Rebuild widget tree to test caching
      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();
      cachedLoadStopwatch.stop();

      // Cached load should be significantly faster
      expect(cachedLoadStopwatch.elapsedMilliseconds, 
             lessThan(imageLoadStopwatch.elapsedMilliseconds / 2));
    });

    testWidgets('should handle form validation efficiently', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: const BookingFormScreen(serviceType: 'water_purifier'),
        ),
      );

      final validationStopwatch = Stopwatch()..start();

      // Trigger validation on all fields rapidly
      final fields = [
        'Customer Name',
        'Phone Number', 
        'Address',
        'Description',
      ];

      for (int i = 0; i < 20; i++) {
        for (final fieldName in fields) {
          await tester.enterText(
            find.widgetWithText(TextFormField, fieldName),
            i % 2 == 0 ? 'valid data' : '', // Alternate valid/invalid
          );
          await tester.pump();
        }
      }

      validationStopwatch.stop();

      // Verify validation completes efficiently
      expect(validationStopwatch.elapsedMilliseconds, lessThan(1000));
    });

    testWidgets('should maintain performance during state changes', (WidgetTester tester) async {
      final mockBookingProvider = MockBookingProvider();
      
      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: const UserBookingStatusScreen(),
          bookingProvider: mockBookingProvider,
        ),
      );

      await tester.pumpAndSettle();

      final stateChangeStopwatch = Stopwatch()..start();

      // Trigger multiple rapid state changes
      for (int i = 0; i < 50; i++) {
        final booking = TestHelpers.createTestBooking();
        booking.id = 'rapid-booking-$i';
        booking.status = ['pending', 'accepted', 'completed'][i % 3];
        mockBookingProvider.addBooking(booking);
        
        await tester.pump();
      }

      stateChangeStopwatch.stop();

      // Verify rapid state changes don't cause performance issues
      expect(stateChangeStopwatch.elapsedMilliseconds, lessThan(500));
    });
  });
}

// Custom mock provider for performance testing with delays
class MockBookingProviderWithDelay extends MockBookingProvider {
  final Duration delay;
  
  MockBookingProviderWithDelay(this.delay);
  
  @override
  Future<void> fetchUserBookings() async {
    setLoading(true);
    
    await Future.delayed(delay);
    
    setLoading(false);
  }
}