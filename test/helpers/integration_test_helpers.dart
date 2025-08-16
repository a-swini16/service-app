import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class IntegrationTestHelpers {
  static const String testApiUrl = 'http://localhost:3000/api';
  String? userToken;
  String? adminToken;
  
  Future<void> setupTestEnvironment() async {
    // Setup test database with clean state
    try {
      final response = await http.post(
        Uri.parse('$testApiUrl/test/reset-database'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode != 200) {
        print('Warning: Failed to setup test environment - ${response.body}');
      }
    } catch (e) {
      print('Warning: Could not connect to test API - $e');
    }
  }
  
  Future<void> cleanupTestEnvironment() async {
    // Clean up test data
    try {
      await http.post(
        Uri.parse('$testApiUrl/test/cleanup'),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('Warning: Could not cleanup test environment - $e');
    }
  }
  
  Future<void> performUserLogin(WidgetTester tester) async {
    // Look for login button or navigate to login screen
    final loginFinder = find.text('Login');
    if (loginFinder.evaluate().isNotEmpty) {
      await tester.tap(loginFinder);
      await tester.pumpAndSettle();
    }
    
    // Fill login form if fields exist
    final phoneFinder = find.byKey(Key('phone'));
    final passwordFinder = find.byKey(Key('password'));
    
    if (phoneFinder.evaluate().isNotEmpty && passwordFinder.evaluate().isNotEmpty) {
      await tester.enterText(phoneFinder, '1234567890');
      await tester.enterText(passwordFinder, 'testpassword123');
      
      // Submit login
      final submitFinder = find.text('Login');
      if (submitFinder.evaluate().isNotEmpty) {
        await tester.tap(submitFinder);
        await tester.pumpAndSettle();
      }
    }
    
    // Store token for API calls
    userToken = 'test_user_token_123';
  }
  
  Future<void> performAdminLogin(WidgetTester tester) async {
    // Navigate to admin login
    final adminLoginFinder = find.text('Admin Login');
    if (adminLoginFinder.evaluate().isNotEmpty) {
      await tester.tap(adminLoginFinder);
      await tester.pumpAndSettle();
    }
    
    // Fill admin login form if fields exist
    final emailFinder = find.byKey(Key('email'));
    final passwordFinder = find.byKey(Key('password'));
    
    if (emailFinder.evaluate().isNotEmpty && passwordFinder.evaluate().isNotEmpty) {
      await tester.enterText(emailFinder, 'admin@test.com');
      await tester.enterText(passwordFinder, 'adminpassword123');
      
      // Submit login
      final submitFinder = find.text('Login');
      if (submitFinder.evaluate().isNotEmpty) {
        await tester.tap(submitFinder);
        await tester.pumpAndSettle();
      }
    }
    
    // Store admin token
    adminToken = 'test_admin_token_123';
  }
  
  Future<void> fillBookingForm(WidgetTester tester, Map<String, dynamic> data) async {
    // Fill booking form fields if they exist
    final fields = {
      'customerName': data['customerName'],
      'customerPhone': data['customerPhone'],
      'customerAddress': data['customerAddress'],
      'description': data['description'],
    };
    
    for (final entry in fields.entries) {
      if (entry.value != null) {
        final finder = find.byKey(Key(entry.key));
        if (finder.evaluate().isNotEmpty) {
          await tester.enterText(finder, entry.value.toString());
        }
      }
    }
    
    await tester.pumpAndSettle();
  }
  
  Future<void> fillPaymentForm(WidgetTester tester) async {
    // Fill payment form with test data if fields exist
    final paymentFields = {
      'cardNumber': '4111111111111111',
      'expiryMonth': '12',
      'expiryYear': '2025',
      'cvv': '123',
      'cardholderName': 'Test User',
    };
    
    for (final entry in paymentFields.entries) {
      final finder = find.byKey(Key(entry.key));
      if (finder.evaluate().isNotEmpty) {
        await tester.enterText(finder, entry.value);
      }
    }
    
    await tester.pumpAndSettle();
  }
  
  Future<String> getLatestBookingId() async {
    try {
      final response = await http.get(
        Uri.parse('$testApiUrl/test/latest-booking'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $userToken',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['bookingId'] ?? 'test_booking_id';
      }
    } catch (e) {
      print('Warning: Could not get latest booking ID - $e');
    }
    return 'test_booking_id';
  }
  
  Future<void> simulateAdminAction(String bookingId, String action) async {
    try {
      final response = await http.put(
        Uri.parse('$testApiUrl/admin/bookings/$bookingId/$action'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
        body: json.encode({
          'adminNotes': 'Test admin action: $action'
        }),
      );
      
      if (response.statusCode != 200) {
        print('Warning: Failed to simulate admin action: $action - ${response.body}');
      }
    } catch (e) {
      print('Warning: Could not simulate admin action - $e');
    }
  }
  
  Future<void> simulateWorkerAssignment(String bookingId) async {
    try {
      final response = await http.put(
        Uri.parse('$testApiUrl/admin/bookings/$bookingId/assign-worker'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
        body: json.encode({
          'employeeId': 'test_employee_id'
        }),
      );
      
      if (response.statusCode != 200) {
        print('Warning: Failed to simulate worker assignment - ${response.body}');
      }
    } catch (e) {
      print('Warning: Could not simulate worker assignment - $e');
    }
  }
  
  Future<void> simulateServiceCompletion(String bookingId) async {
    try {
      final response = await http.put(
        Uri.parse('$testApiUrl/bookings/$bookingId/complete-service'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
        body: json.encode({
          'workerNotes': 'Service completed successfully',
          'actualAmount': 500
        }),
      );
      
      if (response.statusCode != 200) {
        print('Warning: Failed to simulate service completion - ${response.body}');
      }
    } catch (e) {
      print('Warning: Could not simulate service completion - $e');
    }
  }
  
  Future<void> simulatePaymentCompletion(String bookingId) async {
    try {
      final response = await http.post(
        Uri.parse('$testApiUrl/payments/process'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $userToken',
        },
        body: json.encode({
          'bookingId': bookingId,
          'amount': 500,
          'paymentMethod': 'online',
          'paymentDetails': {
            'cardNumber': '4111111111111111',
            'expiryMonth': '12',
            'expiryYear': '2025',
            'cvv': '123'
          }
        }),
      );
      
      if (response.statusCode != 200) {
        print('Warning: Failed to simulate payment completion - ${response.body}');
      }
    } catch (e) {
      print('Warning: Could not simulate payment completion - $e');
    }
  }
  
  Future<String> createTestBooking() async {
    try {
      final response = await http.post(
        Uri.parse('$testApiUrl/bookings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $userToken',
        },
        body: json.encode({
          'serviceType': 'water_purifier',
          'customerName': 'Test User',
          'customerPhone': '1234567890',
          'customerAddress': '123 Test Street',
          'description': 'Test booking description',
          'preferredDate': DateTime.now().add(Duration(days: 1)).toIso8601String(),
          'preferredTime': '10:00 AM',
        }),
      );
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['booking']['_id'] ?? 'test_booking_id';
      }
    } catch (e) {
      print('Warning: Could not create test booking - $e');
    }
    return 'test_booking_id';
  }
  
  Future<String> createTestBookingWithNotificationTracking() async {
    try {
      final response = await http.post(
        Uri.parse('$testApiUrl/bookings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $userToken',
        },
        body: json.encode({
          'serviceType': 'water_purifier',
          'customerName': 'Test User',
          'customerPhone': '1234567890',
          'customerAddress': '123 Test Street',
          'description': 'Test booking with notification tracking',
          'preferredDate': DateTime.now().add(Duration(days: 1)).toIso8601String(),
          'preferredTime': '10:00 AM',
          'trackNotifications': true,
        }),
      );
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['booking']['_id'] ?? 'test_booking_id';
      }
    } catch (e) {
      print('Warning: Could not create test booking with notification tracking - $e');
    }
    return 'test_booking_id';
  }
  
  Future<List<Map<String, dynamic>>> getAdminNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('$testApiUrl/admin/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['notifications'] ?? []);
      }
    } catch (e) {
      print('Warning: Could not get admin notifications - $e');
    }
    return [];
  }
  
  Future<List<Map<String, dynamic>>> getUserNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('$testApiUrl/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $userToken',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['notifications'] ?? []);
      }
    } catch (e) {
      print('Warning: Could not get user notifications - $e');
    }
    return [];
  }
  
  Future<void> simulateNetworkFailure() async {
    // Simulate network failure by setting invalid API URL
    try {
      await http.post(
        Uri.parse('$testApiUrl/test/simulate-network-failure'),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('Network failure simulation: $e');
    }
  }
  
  Future<void> restoreNetwork() async {
    // Restore network connectivity
    try {
      await http.post(
        Uri.parse('$testApiUrl/test/restore-network'),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('Network restoration: $e');
    }
  }
  
  Future<void> simulateOfflineMode() async {
    // Simulate offline mode
    try {
      await http.post(
        Uri.parse('$testApiUrl/test/simulate-offline'),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('Offline mode simulation: $e');
    }
  }
  
  Future<void> restoreOnlineMode() async {
    // Restore online mode
    try {
      await http.post(
        Uri.parse('$testApiUrl/test/restore-online'),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('Online mode restoration: $e');
    }
  }
  
  Future<void> simulateAdminActionWithWebSocket(String bookingId, String action) async {
    // Simulate admin action that triggers WebSocket notification
    try {
      await http.put(
        Uri.parse('$testApiUrl/admin/bookings/$bookingId/$action'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
        body: json.encode({
          'adminNotes': 'WebSocket test action: $action',
          'triggerWebSocket': true
        }),
      );
    } catch (e) {
      print('WebSocket admin action simulation: $e');
    }
  }
  
  Future<void> simulateWorkerAssignmentWithWebSocket(String bookingId) async {
    // Simulate worker assignment with WebSocket notification
    try {
      await http.put(
        Uri.parse('$testApiUrl/admin/bookings/$bookingId/assign-worker'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminToken',
        },
        body: json.encode({
          'employeeId': 'test_employee_id',
          'triggerWebSocket': true
        }),
      );
    } catch (e) {
      print('WebSocket worker assignment simulation: $e');
    }
  }
  
  Future<void> simulateWebSocketDisconnection() async {
    // Simulate WebSocket disconnection
    try {
      await http.post(
        Uri.parse('$testApiUrl/test/disconnect-websocket'),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('WebSocket disconnection simulation: $e');
    }
  }
  
  Future<void> restoreWebSocketConnection() async {
    // Restore WebSocket connection
    try {
      await http.post(
        Uri.parse('$testApiUrl/test/restore-websocket'),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('WebSocket connection restoration: $e');
    }
  }
}