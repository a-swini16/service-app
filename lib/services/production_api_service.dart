import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import '../models/booking_model.dart';

class ProductionApiService {
  static const Duration _timeout = Duration(seconds: 30);
  
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'ServiceApp/1.0',
  };

  /// Get all bookings with production-safe error handling
  static Future<List<BookingModel>> getAllBookings() async {
    try {
      if (kDebugMode) {
        debugPrint('🔑 ProductionApiService: Making API call to /admin/bookings');
        debugPrint('🌐 Base URL: ${AppConstants.baseUrl}');
      }
      
      final uri = Uri.parse('${AppConstants.baseUrl}/admin/bookings');
      
      // Create HTTP client with custom configuration
      final client = http.Client();
      
      try {
        final response = await client.get(uri, headers: _headers).timeout(_timeout);
        
        if (kDebugMode) {
          debugPrint('📡 API Response Status: ${response.statusCode}');
          debugPrint('📡 API Response Headers: ${response.headers}');
          debugPrint('📡 API Response Body Length: ${response.body.length}');
        }
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          
          if (kDebugMode) {
            debugPrint('📊 Parsed JSON keys: ${data.keys.toList()}');
            debugPrint('📊 Success field: ${data['success']}');
            debugPrint('📊 Bookings field type: ${data['bookings'].runtimeType}');
          }
          
          if (data is Map<String, dynamic> && 
              data['success'] == true && 
              data['bookings'] is List) {
            
            final bookingsData = data['bookings'] as List;
            
            if (kDebugMode) {
              debugPrint('📊 Raw bookings count: ${bookingsData.length}');
              if (bookingsData.isNotEmpty) {
                debugPrint('📊 First booking keys: ${(bookingsData[0] as Map).keys.toList()}');
              }
            }
            
            final bookingsList = <BookingModel>[];
            
            for (int i = 0; i < bookingsData.length; i++) {
              try {
                final bookingData = bookingsData[i];
                if (bookingData is Map<String, dynamic>) {
                  
                  // Create safe booking data with all required fields
                  final safeBookingData = <String, dynamic>{
                    '_id': bookingData['_id'] ?? 'temp_${DateTime.now().millisecondsSinceEpoch}_$i',
                    'serviceType': bookingData['serviceType'] ?? 'unknown',
                    'customerName': bookingData['customerName'] ?? 
                      (bookingData['user'] is Map ? bookingData['user']['name'] : null) ?? 'Unknown Customer',
                    'customerPhone': bookingData['customerPhone'] ?? 
                      (bookingData['user'] is Map ? bookingData['user']['phone'] : null) ?? 'N/A',
                    'customerAddress': bookingData['customerAddress'] ?? 'N/A',
                    'description': bookingData['description'] ?? '',
                    'preferredDate': bookingData['preferredDate'] ?? 
                      bookingData['scheduledDate'] ?? DateTime.now().toIso8601String(),
                    'preferredTime': bookingData['preferredTime'] ?? '09:00',
                    'status': bookingData['status'] ?? 'pending',
                    'paymentStatus': bookingData['paymentStatus'] ?? 'pending',
                    'paymentMethod': bookingData['paymentMethod'] ?? 'cash_on_service',
                    'paymentAmount': bookingData['paymentAmount'],
                    'actualAmount': bookingData['actualAmount'],
                    'assignedEmployee': bookingData['assignedEmployee'],
                    'adminNotes': bookingData['adminNotes'],
                    'workerNotes': bookingData['workerNotes'],
                    'rejectionReason': bookingData['rejectionReason'],
                    'createdAt': bookingData['createdAt'] ?? DateTime.now().toIso8601String(),
                    'updatedAt': bookingData['updatedAt'] ?? DateTime.now().toIso8601String(),
                    'acceptedDate': bookingData['acceptedDate'],
                    'rejectedDate': bookingData['rejectedDate'],
                    'assignedDate': bookingData['assignedDate'],
                    'startedDate': bookingData['startedDate'],
                    'completedDate': bookingData['completedDate'],
                    'user': bookingData['user'] ?? {'_id': 'unknown', 'name': 'Unknown User'},
                  };
                  
                  final booking = BookingModel.fromJson(safeBookingData);
                  bookingsList.add(booking);
                  
                  if (kDebugMode && i < 3) {
                    debugPrint('✅ Parsed booking ${i + 1}: ${booking.customerName} - ${booking.serviceType}');
                  }
                }
              } catch (parseError) {
                if (kDebugMode) {
                  debugPrint('❌ Error parsing booking $i: $parseError');
                }
                // Continue with other bookings
              }
            }
            
            if (kDebugMode) {
              debugPrint('✅ Successfully processed ${bookingsList.length} out of ${bookingsData.length} bookings');
            }
            
            return bookingsList;
          } else {
            if (kDebugMode) {
              debugPrint('❌ Invalid API response structure');
            }
            return [];
          }
        } else {
          if (kDebugMode) {
            debugPrint('❌ API call failed with status ${response.statusCode}');
            debugPrint('📡 Error response: ${response.body}');
          }
          return [];
        }
      } finally {
        client.close();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Exception in getAllBookings: $e');
      }
      return [];
    }
  }

  /// Get user bookings by phone number (no auth required)
  static Future<List<BookingModel>> getUserBookingsByPhone(String phone) async {
    try {
      if (kDebugMode) {
        debugPrint('🔑 ProductionApiService: Getting user bookings for phone: $phone');
      }
      
      final uri = Uri.parse('${AppConstants.baseUrl}/bookings/user/$phone');
      final client = http.Client();
      
      try {
        final response = await client.get(uri, headers: _headers).timeout(_timeout);
        
        if (kDebugMode) {
          debugPrint('📡 User Bookings Response Status: ${response.statusCode}');
        }
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          
          if (data is Map<String, dynamic> && 
              data['success'] == true && 
              data['bookings'] is List) {
            
            final bookingsData = data['bookings'] as List;
            
            if (kDebugMode) {
              debugPrint('📊 User bookings count: ${bookingsData.length}');
            }
            
            final bookingsList = <BookingModel>[];
            
            for (int i = 0; i < bookingsData.length; i++) {
              try {
                final bookingData = bookingsData[i];
                if (bookingData is Map<String, dynamic>) {
                  
                  // Create safe booking data
                  final safeBookingData = <String, dynamic>{
                    '_id': bookingData['_id'] ?? 'temp_${DateTime.now().millisecondsSinceEpoch}_$i',
                    'serviceType': bookingData['serviceType'] ?? 'unknown',
                    'customerName': bookingData['customerName'] ?? 'Unknown Customer',
                    'customerPhone': bookingData['customerPhone'] ?? phone,
                    'customerAddress': bookingData['customerAddress'] ?? 'N/A',
                    'description': bookingData['description'] ?? '',
                    'preferredDate': bookingData['preferredDate'] ?? DateTime.now().toIso8601String(),
                    'preferredTime': bookingData['preferredTime'] ?? '09:00',
                    'status': bookingData['status'] ?? 'pending',
                    'paymentStatus': bookingData['paymentStatus'] ?? 'pending',
                    'paymentMethod': bookingData['paymentMethod'] ?? 'cash_on_service',
                    'paymentAmount': bookingData['paymentAmount'],
                    'actualAmount': bookingData['actualAmount'],
                    'assignedEmployee': bookingData['assignedEmployee'],
                    'adminNotes': bookingData['adminNotes'],
                    'workerNotes': bookingData['workerNotes'],
                    'rejectionReason': bookingData['rejectionReason'],
                    'createdAt': bookingData['createdAt'] ?? DateTime.now().toIso8601String(),
                    'updatedAt': bookingData['updatedAt'] ?? DateTime.now().toIso8601String(),
                    'acceptedDate': bookingData['acceptedDate'],
                    'rejectedDate': bookingData['rejectedDate'],
                    'assignedDate': bookingData['assignedDate'],
                    'startedDate': bookingData['startedDate'],
                    'completedDate': bookingData['completedDate'],
                    'user': bookingData['user'] ?? {'_id': 'unknown', 'name': 'Unknown User'},
                  };
                  
                  final booking = BookingModel.fromJson(safeBookingData);
                  bookingsList.add(booking);
                }
              } catch (parseError) {
                if (kDebugMode) {
                  debugPrint('❌ Error parsing user booking $i: $parseError');
                }
              }
            }
            
            if (kDebugMode) {
              debugPrint('✅ Successfully processed ${bookingsList.length} user bookings');
            }
            
            return bookingsList;
          } else {
            if (kDebugMode) {
              debugPrint('❌ Invalid user bookings response structure');
            }
            return [];
          }
        } else if (response.statusCode == 404) {
          if (kDebugMode) {
            debugPrint('📭 No bookings found for user: $phone');
          }
          return [];
        } else {
          if (kDebugMode) {
            debugPrint('❌ User bookings API call failed with status ${response.statusCode}');
          }
          return [];
        }
      } finally {
        client.close();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Exception in getUserBookingsByPhone: $e');
      }
      return [];
    }
  }

  /// Test API connectivity
  static Future<bool> testConnection() async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}/health');
      final client = http.Client();
      
      try {
        final response = await client.get(uri, headers: _headers).timeout(_timeout);
        return response.statusCode == 200;
      } finally {
        client.close();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Connection test failed: $e');
      }
      return false;
    }
  }

  /// Send test notification
  static Future<Map<String, dynamic>> sendTestNotification({
    required String title,
    required String message,
  }) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}/notifications/test');
      final client = http.Client();
      
      final body = jsonEncode({
        'title': title,
        'message': message,
        'type': 'test',
        'recipient': 'all',
        'priority': 'medium',
      });
      
      try {
        final response = await client.post(
          uri,
          headers: _headers,
          body: body,
        ).timeout(_timeout);
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          return {
            'success': data['success'] ?? false,
            'message': data['message'] ?? 'Unknown response',
            'notificationId': data['notification']?['id'],
          };
        } else {
          return {
            'success': false,
            'message': 'HTTP ${response.statusCode}: ${response.body}',
          };
        }
      } finally {
        client.close();
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  static Future<BookingModel?> updateBooking(String bookingId, Map<String, dynamic> updatedData) async {
    try {
      if (kDebugMode) {
        debugPrint('🔑 ProductionApiService: Updating booking $bookingId');
        debugPrint('📝 Update data: $updatedData');
      }
      
      final uri = Uri.parse('${AppConstants.baseUrl}/admin/bookings/$bookingId');
      final client = http.Client();
      
      try {
        final response = await client.put(
          uri,
          headers: _headers,
          body: jsonEncode(updatedData),
        ).timeout(_timeout);
        
        if (kDebugMode) {
          debugPrint('📡 Update Response Status: ${response.statusCode}');
        }
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          
          if (data is Map<String, dynamic> && 
              data['success'] == true && 
              data['booking'] is Map<String, dynamic>) {
            
            if (kDebugMode) {
              debugPrint('✅ Booking updated successfully');
            }
            
            return BookingModel.fromJson(data['booking']);
          } else {
            if (kDebugMode) {
              debugPrint('❌ Failed to update booking: Invalid response structure');
            }
            return null;
          }
        } else {
          if (kDebugMode) {
            debugPrint('❌ API call failed with status ${response.statusCode}');
            debugPrint('📡 Error response: ${response.body}');
          }
          return null;
        }
      } finally {
        client.close();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Exception in updateBooking: $e');
      }
      return null;
    }
  }
}