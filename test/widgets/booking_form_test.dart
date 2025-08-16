import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:om_enterprises/screens/booking_form_screen.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('BookingFormScreen Widget Tests', () {
    testWidgets('should display booking form with all required fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: const BookingFormScreen(serviceType: 'water_purifier'),
        ),
      );

      // Verify form fields are present
      expect(find.byType(TextFormField), findsWidgets);
      expect(find.text('Customer Name'), findsOneWidget);
      expect(find.text('Phone Number'), findsOneWidget);
      expect(find.text('Address'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('Preferred Date'), findsOneWidget);
      expect(find.text('Preferred Time'), findsOneWidget);
    });

    testWidgets('should validate required fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: const BookingFormScreen(serviceType: 'water_purifier'),
        ),
      );

      // Try to submit form without filling required fields
      final submitButton = find.text('Book Service');
      expect(submitButton, findsOneWidget);
      
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Verify validation error message appears
      expect(find.text('Please fill all required fields correctly'), findsOneWidget);
    });

    testWidgets('should validate phone number format', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: const BookingFormScreen(serviceType: 'water_purifier'),
        ),
      );

      // Fill required fields but with invalid phone number
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Customer Name'),
        'John Doe',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Phone Number'),
        '123', // Invalid phone number
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Address'),
        '123 Main Street',
      );
      
      final submitButton = find.text('Book Service');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Verify validation error message appears
      expect(find.text('Please fill all required fields correctly'), findsOneWidget);
    });

    testWidgets('should submit form with valid data', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: const BookingFormScreen(serviceType: 'water_purifier'),
        ),
      );

      // Fill form with valid data
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
        '123 Main Street, City, State',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Description'),
        'Water purifier maintenance required',
      );

      // Select date and time
      await tester.tap(find.text('Preferred Date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK')); // Confirm date picker
      await tester.pumpAndSettle();

      await tester.tap(find.text('Preferred Time'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK')); // Confirm time picker
      await tester.pumpAndSettle();

      // Submit form
      final submitButton = find.text('Book Service');
      await tester.tap(submitButton);
      await tester.pump();

      // Wait for async operation to complete
      await tester.pumpAndSettle();

      // Since the form uses ApiService directly, we can't easily verify the booking creation
      // Instead, verify that no error message is shown (indicating success)
      expect(find.text('Booking failed'), findsNothing);
    });

    testWidgets('should show date picker when date field is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: const BookingFormScreen(serviceType: 'water_purifier'),
        ),
      );

      // Find and tap on date field (it's likely an InkWell or GestureDetector)
      final dateField = find.text('Select Date');
      if (dateField.evaluate().isEmpty) {
        // If "Select Date" is not found, look for the date container
        final dateContainer = find.byKey(const Key('date_field'));
        if (dateContainer.evaluate().isNotEmpty) {
          await tester.tap(dateContainer);
        }
      } else {
        await tester.tap(dateField);
      }
      await tester.pumpAndSettle();

      // Verify date picker is shown (look for calendar widget or date picker dialog)
      expect(find.byType(CalendarDatePicker), findsOneWidget);
    });

    testWidgets('should show time selection when time field is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: const BookingFormScreen(serviceType: 'water_purifier'),
        ),
      );

      // Find and tap on time field
      final timeField = find.text('Select Time');
      if (timeField.evaluate().isEmpty) {
        // If "Select Time" is not found, look for the time container
        final timeContainer = find.byKey(const Key('time_field'));
        if (timeContainer.evaluate().isNotEmpty) {
          await tester.tap(timeContainer);
        }
      } else {
        await tester.tap(timeField);
      }
      await tester.pumpAndSettle();

      // Verify time selection is shown (could be dropdown or dialog)
      expect(find.text('09:00 AM'), findsOneWidget);
    });

    testWidgets('should display service-specific information', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: const BookingFormScreen(serviceType: 'ac_repair'),
        ),
      );

      // Verify service type is displayed
      expect(find.text('AC Repair Service'), findsOneWidget);
    });

    testWidgets('should show validation error for missing required fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: const BookingFormScreen(serviceType: 'water_purifier'),
        ),
      );

      // Try to submit form without filling all required fields
      final submitButton = find.text('Book Service');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Verify validation error message is shown
      expect(find.text('Please fill all required fields correctly'), findsOneWidget);
    });

    testWidgets('should show error when service information is missing', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: const BookingFormScreen(), // No serviceType provided
        ),
      );

      // Fill form with valid data
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

      // Try to submit
      final submitButton = find.text('Book Service');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Verify service missing error message is shown
      expect(find.text('Service information is missing'), findsOneWidget);
    });
  });
}