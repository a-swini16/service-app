import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

/// Integration test for notification system
/// This test verifies that the Flutter app can trigger and receive notifications
void main() {
  group('Notification Integration Tests', () {
    
    // Test 1: Test backend notification endpoint
    test('Backend notification endpoint should work', () async {
      const String baseUrl = 'https://service-app-backend-6jpw.onrender.com/api';
      
      final testData = {
        'title': '🧪 Flutter Test Notification',
        'message': 'Testing notification from Flutter integration test',
        'type': 'flutter_test'
      };
      
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/notifications/test'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(testData),
        ).timeout(const Duration(seconds: 30));
        
        print('📡 Response Status: ${response.statusCode}');
        print('📡 Response Body: ${response.body}');
        
        expect(response.statusCode, equals(200));
        
        final responseData = jsonDecode(response.body);
        expect(responseData['success'], equals(true));
        expect(responseData['notification'], isNotNull);
        
        print('✅ Backend notification test passed!');
        print('   Notification ID: ${responseData['notification']['id']}');
        
      } catch (e) {
        print('❌ Backend notification test failed: $e');
        fail('Backend notification endpoint failed: $e');
      }
    });
    
    // Test 2: Test admin bookings endpoint
    test('Admin bookings endpoint should return data', () async {
      const String baseUrl = 'https://service-app-backend-6jpw.onrender.com/api';
      
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/admin/bookings'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: 30));
        
        print('📡 Admin Bookings Status: ${response.statusCode}');
        
        expect(response.statusCode, equals(200));
        
        final responseData = jsonDecode(response.body);
        expect(responseData['success'], equals(true));
        expect(responseData['bookings'], isNotNull);
        expect(responseData['bookings'], isA<List>());
        
        final bookings = responseData['bookings'] as List;
        print('✅ Admin bookings test passed!');
        print('   Total bookings: ${bookings.length}');
        
        if (bookings.isNotEmpty) {
          final sample = bookings.first;
          print('   Sample booking: ${sample['customerName']} - ${sample['serviceType']}');
        }
        
      } catch (e) {
        print('❌ Admin bookings test failed: $e');
        fail('Admin bookings endpoint failed: $e');
      }
    });
    
    // Test 3: Test user bookings endpoint
    test('User bookings endpoint should work', () async {
      const String baseUrl = 'https://service-app-backend-6jpw.onrender.com/api';
      const String testPhone = '6371448994';
      
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/bookings/user/$testPhone'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: 30));
        
        print('📡 User Bookings Status: ${response.statusCode}');
        
        expect(response.statusCode, equals(200));
        
        final responseData = jsonDecode(response.body);
        expect(responseData['success'], equals(true));
        expect(responseData['bookings'], isNotNull);
        expect(responseData['bookings'], isA<List>());
        
        final bookings = responseData['bookings'] as List;
        print('✅ User bookings test passed!');
        print('   Bookings for $testPhone: ${bookings.length}');
        
      } catch (e) {
        print('❌ User bookings test failed: $e');
        fail('User bookings endpoint failed: $e');
      }
    });
    
    // Test 4: Test OneSignal direct API
    test('OneSignal direct API should work', () async {
      const String appId = 'f6dbfa0d-b44d-4fce-9e63-c85c5b200d5d';
      const String restApiKey = 'os_v2_app_63n7udnujvh45htdzbofwianlwcneea4ayfu3wetezxlhxo2io4zull7e3nzicmsx4vmnt77n2eseczlo4n7dsrftly7bgeglkvr2fa';
      
      final message = {
        'app_id': appId,
        'included_segments': ['All'],
        'headings': {'en': '🧪 Flutter Integration Test'},
        'contents': {'en': 'Testing OneSignal from Flutter integration test'},
        'data': {
          'type': 'flutter_integration_test',
          'timestamp': DateTime.now().toIso8601String(),
        }
      };
      
      try {
        final response = await http.post(
          Uri.parse('https://onesignal.com/api/v1/notifications'),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Authorization': 'Basic $restApiKey',
          },
          body: jsonEncode(message),
        ).timeout(const Duration(seconds: 30));
        
        print('📡 OneSignal Status: ${response.statusCode}');
        print('📡 OneSignal Response: ${response.body}');
        
        expect(response.statusCode, equals(200));
        
        final responseData = jsonDecode(response.body);
        expect(responseData['id'], isNotNull);
        
        print('✅ OneSignal direct test passed!');
        print('   Notification ID: ${responseData['id']}');
        print('   Recipients: ${responseData['recipients'] ?? 'Unknown'}');
        
      } catch (e) {
        print('❌ OneSignal direct test failed: $e');
        fail('OneSignal direct API failed: $e');
      }
    });
    
    // Test 5: Simulate booking creation notification flow
    test('Booking creation notification flow should work', () async {
      const String baseUrl = 'https://service-app-backend-6jpw.onrender.com/api';
      
      // First test the notification endpoint
      final testData = {
        'title': '🆕 New Booking Created!',
        'message': 'New AC Repair booking from Flutter Test. This simulates a real booking notification.',
        'type': 'booking_created_test'
      };
      
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/notifications/test'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(testData),
        ).timeout(const Duration(seconds: 30));
        
        print('📡 Booking Notification Status: ${response.statusCode}');
        print('📡 Booking Notification Response: ${response.body}');
        
        expect(response.statusCode, equals(200));
        
        final responseData = jsonDecode(response.body);
        expect(responseData['success'], equals(true));
        
        print('✅ Booking notification flow test passed!');
        print('   This simulates what happens when a user creates a booking');
        print('   Admin should receive this notification in real-time');
        
      } catch (e) {
        print('❌ Booking notification flow test failed: $e');
        fail('Booking notification flow failed: $e');
      }
    });
  });
}

/// Helper function to run all tests and print summary
void runNotificationTests() async {
  print('🧪 Running Flutter Notification Integration Tests...\n');
  
  // This would be called by the test runner
  // The actual tests are defined above
}