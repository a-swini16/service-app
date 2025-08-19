import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:om_enterprises/services/notification_service.dart';
import '../constants/app_constants.dart';
import '../models/booking_model.dart';
import '../models/user_model.dart';
import '../utils/logger.dart';
import 'error_handling_service.dart';
import 'network_recovery_service.dart';

class ApiService {
  static const _storage = FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';
  static const String _userTypeKey = 'user_type'; // 'user' or 'admin'

  static late Dio _dio;
  static final ErrorHandlingService _errorHandler = ErrorHandlingService();
  static final NetworkRecoveryService _networkRecovery =
      NetworkRecoveryService();

  static bool _initialized = false;

  /// Initialize the API service with error handling
  static Future<void> initialize() async {
    if (_initialized) return;

    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ));

    // Add retry interceptor
    _dio.interceptors.add(_networkRecovery.createRetryInterceptor());

    // Add auth interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        Logger.debug('Request intercepted: ${options.method} ${options.path}');
        handler.next(options);
      },
      onError: (error, handler) async {
        // Handle token refresh for 401 errors
        if (error.response?.statusCode == 401) {
          final refreshed = await _refreshToken();
          if (refreshed) {
            // Retry the request with new token
            final token = await getToken();
            error.requestOptions.headers['Authorization'] = 'Bearer $token';
            try {
              final response = await _dio.fetch(error.requestOptions);
              handler.resolve(response);
              Logger.info('Token refresh successful');
              return;
            } catch (e) {
              Logger.error('Request failed after token refresh', error: e);
              // If retry fails, continue with original error
            }
          }
        }
        handler.next(error);
      },
    ));

    await _networkRecovery.initialize();
    _initialized = true;
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<void> removeToken() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: _userTypeKey);
  }

  static Future<void> saveUserType(String userType) async {
    await _storage.write(key: _userTypeKey, value: userType);
  }

  static Future<String?> getUserType() async {
    return await _storage.read(key: _userTypeKey);
  }

  /// Execute API request with error handling and recovery
  static Future<T> _executeRequest<T>(
    Future<Response> Function() request, {
    String? requestId,
  }) async {
    await initialize();

    return await _networkRecovery.executeWithRecovery<T>(
      () async {
        try {
          final response = await request();
          return response.data as T;
        } catch (error) {
          final appError = await _errorHandler.handleError(
            error,
            context: 'API Request: $requestId',
          );
          throw appError;
        }
      },
      requestId: requestId,
    );
  }

  /// Refresh authentication token
  static Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) return false;

      final response = await _dio.post('/api/auth/refresh', data: {
        'refreshToken': refreshToken,
      });

      if (response.statusCode == 200 && response.data['success']) {
        final newToken = response.data['token'];
        await saveToken(newToken);
        return true;
      }

      return false;
    } catch (error) {
      await removeToken(); // Clear invalid tokens
      return false;
    }
  }

  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await getToken();
    Logger.debug('Retrieved token: ${token != null ? '${token.substring(0, 20)}...' : 'null'}');
    
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    
    Logger.debug('Auth headers: ${headers.keys.join(', ')}');
    Logger.debug('Request headers: ${headers}');
    return headers;
  }

  /// Public method to get authentication headers
  static Future<Map<String, String>> getAuthHeaders() async {
    return await _getAuthHeaders();
  }

  static Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
    };
  }

  // Update Booking
  static Future<Map<String, dynamic>> updateBooking(String bookingId, Map<String, dynamic> updateData) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/bookings/update/$bookingId'),
        headers: await _getAuthHeaders(),
        body: jsonEncode(updateData),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Auth Services
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String address,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/register'),
        headers: _getHeaders(),
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
          'address': address,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success']) {
        // Store both access and refresh tokens
        await saveToken(data['accessToken']);
        await _storage.write(key: 'refresh_token', value: data['refreshToken']);
        await saveUserType('user');
      }

      return data;
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      Logger.info('Attempting user login...');
      Logger.debug('Base URL: ${AppConstants.baseUrl}');
      
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/login'),
        headers: _getHeaders(),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(Duration(seconds: 30)); // Add timeout

      Logger.debug('User login response status: ${response.statusCode}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        // Store both access and refresh tokens
        await saveToken(data['accessToken']);
        await _storage.write(key: 'refresh_token', value: data['refreshToken']);
        await saveUserType('user');
        Logger.info('User login successful, tokens stored');
      } else {
        Logger.warning('User login failed: ${data['message'] ?? 'Unknown error'}');
      }

      return data;
    } catch (e) {
      Logger.error('User login exception', error: e);
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> adminLogin({
    required String username,
    required String password,
  }) async {
    try {
      Logger.info('Attempting admin login...');
      Logger.debug('Base URL: ${AppConstants.baseUrl}');
      
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/admin/login'),
        headers: _getHeaders(),
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      ).timeout(Duration(seconds: 30)); // Add timeout

      Logger.debug('Admin login response status: ${response.statusCode}');
      Logger.debug('Admin login response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        // Store both access and refresh tokens
        await saveToken(data['accessToken']);
        await _storage.write(key: 'refresh_token', value: data['refreshToken']);
        await saveUserType('admin');
        Logger.info('Admin login successful, tokens stored');
      } else {
        Logger.warning('Admin login failed: ${data['message'] ?? 'Unknown error'}');
      }

      return data;
    } catch (e) {
      Logger.error('Admin login exception', error: e);
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/refresh'),
        headers: _getHeaders(),
        body: jsonEncode({
          'refreshToken': refreshToken,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        // Store new tokens
        await saveToken(data['accessToken']);
        await _storage.write(key: 'refresh_token', value: data['refreshToken']);
      }

      return data;
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> logout(String refreshToken) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/logout'),
        headers: headers,
        body: jsonEncode({
          'refreshToken': refreshToken,
        }),
      );

      // Clear tokens regardless of response
      await removeToken();

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      // Clear tokens even if network fails
      await removeToken();
      return {
        'success': true,
        'message': 'Logged out locally',
      };
    }
  }

  static Future<Map<String, dynamic>> logoutAllDevices() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/logout-all'),
        headers: headers,
      );

      // Clear tokens regardless of response
      await removeToken();

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      // Clear tokens even if network fails
      await removeToken();
      return {
        'success': true,
        'message': 'Logged out locally',
      };
    }
  }

  static Future<Map<String, dynamic>> getActiveSessions() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/auth/sessions'),
        headers: headers,
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> revokeSession(String sessionId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}/auth/sessions/$sessionId'),
        headers: headers,
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<UserModel?> getProfile() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/auth/profile'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return UserModel.fromJson(data['user']);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Booking Services
  static Future<Map<String, dynamic>> createBooking(
      Map<String, dynamic> bookingData) async {
    try {
      final headers = await _getAuthHeaders();

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/bookings'),
        headers: headers,
        body: jsonEncode(bookingData),
      );

      final responseData = jsonDecode(response.body);
      
      // Create notification for admin when booking is created
      if (responseData['success'] && responseData['booking'] != null) {
        final booking = responseData['booking'];
        final bookingId = booking['_id'] ?? booking['id'];
        final customerName = bookingData['customerName'] ?? 'Customer';
        final serviceType = bookingData['serviceType'] ?? 'service';
        
        // Create admin notification
        await NotificationService.createAdminNotification({
          'title': 'New Booking Request',
          'message': '$customerName has requested a $serviceType service',
          'type': 'booking_created',
          'priority': 'high',
          'relatedBookingId': bookingId,
          'data': {
            'bookingId': bookingId,
            'serviceType': serviceType,
            'customerName': customerName,
          },
          'actionUrl': '/admin/bookings',
        });
      }
      
      return responseData;
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<List<BookingModel>> getUserBookings() async {
    try {
      Logger.debug('Making API call to /bookings/my-bookings');
      Logger.debug('Base URL: ${AppConstants.baseUrl}');
      
      final headers = await _getAuthHeaders();

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/bookings/my-bookings'),
        headers: headers,
      );

      Logger.debug('User Bookings Response Status: ${response.statusCode}');
      
      if (response.body.isNotEmpty) {
        Logger.debug('User Bookings Response Body (first 500 chars): ${response.body.length > 500 ? response.body.substring(0, 500) + '...' : response.body}');
      }

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          if (data['success'] == true && data['bookings'] != null) {
            final bookingsList = (data['bookings'] as List)
                .map((booking) => BookingModel.fromJson(booking))
                .toList();
            Logger.info('Successfully parsed ${bookingsList.length} bookings');
            return bookingsList;
          } else {
            Logger.warning('User bookings API returned success: false - ${data['message'] ?? 'Unknown error'}');
            return [];
          }
        } catch (parseError) {
          Logger.error('User bookings JSON parsing error', error: parseError);
          Logger.error('Failed to parse JSON response', error: parseError);
          return [];
        }
      } else if (response.statusCode == 401) {
        Logger.warning('User bookings authentication required - Status 401');
        return [];
      } else if (response.statusCode == 404) {
        Logger.warning('User bookings endpoint not found - Status 404');
        return [];
      } else {
        Logger.error('User bookings API call failed with status ${response.statusCode}');
        Logger.debug('Error response: ${response.body}');
        return [];
      }
    } catch (e) {
      Logger.error('Exception in getUserBookings', error: e, stackTrace: StackTrace.current);
      return [];
    }
  }

  static Future<List<BookingModel>> getAllBookings() async {
    try {
      await initialize();
      
      Logger.debug('Making API call to /admin/bookings');
      Logger.debug('Base URL: ${AppConstants.baseUrl}');
      
      final headers = await _getAuthHeaders();
      
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/admin/bookings'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      Logger.debug('Response intercepted: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          Logger.debug('API Response Data Keys: ${data.keys.toList()}');
          
          if (data['success'] == true && data['bookings'] != null) {
            final bookingsData = data['bookings'] as List;
            Logger.debug('Raw bookings count: ${bookingsData.length}');
            
            if (bookingsData.isEmpty) {
              Logger.warning('No bookings found in database');
              return [];
            }
            
            final bookingsList = <BookingModel>[];
            for (int i = 0; i < bookingsData.length; i++) {
              try {
                final bookingData = bookingsData[i] as Map<String, dynamic>;
                
                // Ensure required fields exist with defaults
                final processedBooking = {
                  '_id': bookingData['_id'] ?? 'unknown_${DateTime.now().millisecondsSinceEpoch}',
                  'user': bookingData['user'] ?? {'_id': 'unknown', 'name': 'Unknown User', 'phone': 'N/A'},
                  'serviceType': bookingData['serviceType'] ?? 'unknown',
                  'customerName': bookingData['customerName'] ?? 'Unknown Customer',
                  'customerPhone': bookingData['customerPhone'] ?? 'N/A',
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
                };
                
                final booking = BookingModel.fromJson(processedBooking);
                bookingsList.add(booking);
                
              } catch (parseError) {
                Logger.error('Error parsing booking at index $i', error: parseError);
                Logger.debug('Problematic booking data: ${bookingsData[i]}');
                // Continue with other bookings instead of failing completely
              }
            }
            
            Logger.info('Successfully parsed ${bookingsList.length} out of ${bookingsData.length} bookings');
            return bookingsList;
          } else {
            Logger.warning('API returned success=false or null bookings: ${data['message'] ?? 'Unknown error'}');
            return [];
          }
        } catch (parseError) {
          Logger.error('JSON parsing error', error: parseError);
          Logger.debug('Raw response (first 1000 chars): ${response.body.length > 1000 ? response.body.substring(0, 1000) + '...' : response.body}');
          return [];
        }
      } else {
        Logger.error('API call failed with status ${response.statusCode}');
        Logger.debug('Error response: ${response.body}');
        return [];
      }
    } catch (e) {
      Logger.error('Exception in getAllBookings', error: e);
      return [];
    }
  }

  // Accept Booking (Admin)
  static Future<Map<String, dynamic>> acceptBooking(
    String bookingId, {
    String? adminNotes,
  }) async {
    try {
      final headers = await _getAuthHeaders();

      final body = <String, dynamic>{};
      if (adminNotes != null && adminNotes.isNotEmpty) {
        body['adminNotes'] = adminNotes;
      }

      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/admin/bookings/$bookingId/accept'),
        headers: headers,
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Reject Booking (Admin)
  static Future<Map<String, dynamic>> rejectBooking(
    String bookingId,
    String rejectionReason,
  ) async {
    try {
      final headers = await _getAuthHeaders();

      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/admin/bookings/$bookingId/reject'),
        headers: headers,
        body: jsonEncode({
          'rejectionReason': rejectionReason,
        }),
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Update Admin Notes
  static Future<Map<String, dynamic>> updateAdminNotes(
    String bookingId,
    String adminNotes,
  ) async {
    try {
      final headers = await _getAuthHeaders();

      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/admin/bookings/$bookingId/notes'),
        headers: headers,
        body: jsonEncode({
          'adminNotes': adminNotes,
        }),
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Assign Worker to Booking (Admin)
  static Future<Map<String, dynamic>> assignWorker(
    String bookingId,
    String workerId,
  ) async {
    try {
      final headers = await _getAuthHeaders();

      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/admin/bookings/$bookingId/assign'),
        headers: headers,
        body: jsonEncode({
          'employeeId': workerId,
        }),
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Start Work (Worker/Admin)
  static Future<Map<String, dynamic>> startWork(
    String bookingId, {
    String? workerNotes,
  }) async {
    try {
      final headers = await _getAuthHeaders();

      final body = <String, dynamic>{};
      if (workerNotes != null && workerNotes.isNotEmpty) {
        body['workerNotes'] = workerNotes;
      }

      final response = await http.put(
        Uri.parse(
            '${AppConstants.baseUrl}/admin/bookings/$bookingId/start-work'),
        headers: headers,
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Complete Work (Worker/Admin)
  static Future<Map<String, dynamic>> completeWork(
    String bookingId, {
    String? workerNotes,
    double? actualAmount,
  }) async {
    try {
      final headers = await _getAuthHeaders();

      final body = <String, dynamic>{
        'adminConfirmation': true, // Always require admin confirmation
      };
      if (workerNotes != null && workerNotes.isNotEmpty) {
        body['workerNotes'] = workerNotes;
      }
      if (actualAmount != null) {
        body['actualAmount'] = actualAmount;
      }

      print('🔧 Completing work for booking: $bookingId');
      print('📋 Request body: $body');

      final response = await http.put(
        Uri.parse(
            '${AppConstants.baseUrl}/admin/bookings/$bookingId/complete-work'),
        headers: headers,
        body: jsonEncode(body),
      );

      print('📡 Complete work response status: ${response.statusCode}');
      print('📡 Complete work response body: ${response.body}');

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      print('❌ Complete work error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Complete Payment (User/Admin)
  static Future<Map<String, dynamic>> completePayment(
    String bookingId,
    double actualAmount,
    String paymentMethod,
  ) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.put(
        Uri.parse(
            '${AppConstants.baseUrl}/bookings/$bookingId/complete-payment'),
        headers: headers,
        body: jsonEncode({
          'actualAmount': actualAmount,
          'paymentMethod': paymentMethod,
        }),
      );
      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Create Payment Transaction
  static Future<Map<String, dynamic>> createPaymentTransaction(
    Map<String, dynamic> paymentData,
  ) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/payment/create'),
        headers: headers,
        body: jsonEncode(paymentData),
      );
      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Process Payment
  static Future<Map<String, dynamic>> processPayment(
    String transactionId,
    Map<String, dynamic> paymentDetails,
  ) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/payment/process/$transactionId'),
        headers: headers,
        body: jsonEncode(paymentDetails),
      );
      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get Payment Transaction
  static Future<Map<String, dynamic>> getPaymentTransaction(
    String transactionId,
  ) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/payment/transaction/$transactionId'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get Payment History
  static Future<Map<String, dynamic>> getPaymentHistory({
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (status != null) {
        queryParams['status'] = status;
      }

      final uri = Uri.parse('${AppConstants.baseUrl}/payment/history')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);
      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get Available Workers (Enhanced)
  static Future<Map<String, dynamic>> getAvailableWorkers({
    required String serviceType,
    DateTime? preferredDate,
    String? preferredTime,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{
        'serviceType': serviceType,
      };

      if (preferredDate != null) {
        queryParams['preferredDate'] = preferredDate.toIso8601String();
      }

      if (preferredTime != null) {
        queryParams['preferredTime'] = preferredTime;
      }

      final uri = Uri.parse('${AppConstants.baseUrl}/employees/available')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      }
      return {
        'success': false,
        'employees': [],
        'message': 'Failed to fetch available workers'
      };
    } catch (e) {
      return {
        'success': false,
        'employees': [],
        'message': 'Network error: ${e.toString()}'
      };
    }
  }

  // Assign Worker to Booking (Enhanced)
  static Future<Map<String, dynamic>> assignWorkerToBooking({
    required String bookingId,
    required String workerId,
  }) async {
    try {
      final headers = await _getAuthHeaders();

      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/admin/bookings/$bookingId/assign'),
        headers: headers,
        body: jsonEncode({
          'employeeId': workerId,
        }),
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get Worker Availability Statistics
  static Future<Map<String, dynamic>> getWorkerAvailabilityStats() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/employees/availability/stats'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      }
      return {
        'success': false,
        'message': 'Failed to fetch availability statistics'
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Get Workers by Skill for Service Type
  static Future<Map<String, dynamic>> getWorkersBySkill(
      String serviceType) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/employees/skills/$serviceType'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      }
      return {
        'success': false,
        'workers': [],
        'message': 'Failed to fetch workers by skill'
      };
    } catch (e) {
      return {
        'success': false,
        'workers': [],
        'message': 'Network error: ${e.toString()}'
      };
    }
  }

  // Get User Notifications
  static Future<Map<String, dynamic>> getUserNotifications(String userId,
      {int page = 1, int limit = 20}) async {
    try {
      final headers = await _getAuthHeaders();
      final uri =
          Uri.parse('${AppConstants.baseUrl}/notifications/user/$userId')
              .replace(queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      });

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      }
      return {
        'success': false,
        'notifications': [],
        'total': 0,
        'unreadCount': 0
      };
    } catch (e) {
      return {
        'success': false,
        'notifications': [],
        'total': 0,
        'unreadCount': 0
      };
    }
  }

  // Get Admin Notifications
  static Future<Map<String, dynamic>> getAdminNotifications(
      {int page = 1, int limit = 20}) async {
    try {
      final headers = await _getAuthHeaders();
      final uri = Uri.parse('${AppConstants.baseUrl}/notifications/admin')
          .replace(queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      });

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      }
      return {
        'success': false,
        'notifications': [],
        'total': 0,
        'unreadCount': 0
      };
    } catch (e) {
      return {
        'success': false,
        'notifications': [],
        'total': 0,
        'unreadCount': 0
      };
    }
  }

  
  // Admin token management
  static Future<String?> getAdminToken() async {
    return await _storage.read(key: 'admin_access_token');
  }

  static Future<void> saveAdminToken(String token) async {
    await _storage.write(key: 'admin_access_token', value: token);
  }

  static Future<void> removeAdminToken() async {
    await _storage.delete(key: 'admin_access_token');
  }

  static Future<Map<String, String>> getAdminAuthHeaders() async {
    final token = await getAdminToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Mark notification as read
  static Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/notifications/$notificationId/read'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Mark all notifications as read
  static Future<bool> markAllNotificationsAsRead() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/notifications/admin/read-all'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Sync-specific methods for data synchronization

  // Get booking by ID
  Future<Map<String, dynamic>?> getBooking(String bookingId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/bookings/$bookingId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return data['booking'];
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Update booking
  Future<Map<String, dynamic>?> updateBookingRecord(
      String bookingId, Map<String, dynamic> bookingData) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/bookings/$bookingId'),
        headers: headers,
        body: jsonEncode(bookingData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return data['booking'];
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get updated bookings since last sync
  Future<List<Map<String, dynamic>>> getUpdatedBookings(
      DateTime? lastSyncTime) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{};

      if (lastSyncTime != null) {
        queryParams['since'] = lastSyncTime.toIso8601String();
      }

      final uri = Uri.parse('${AppConstants.baseUrl}/bookings/sync/updated')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return List<Map<String, dynamic>>.from(data['bookings']);
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Create notification
  Future<Map<String, dynamic>?> createNotification(
      Map<String, dynamic> notificationData) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/notifications'),
        headers: headers,
        body: jsonEncode(notificationData),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return data['notification'];
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get updated notifications since last sync
  Future<List<Map<String, dynamic>>> getUpdatedNotifications(
      DateTime? lastSyncTime) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{};

      if (lastSyncTime != null) {
        queryParams['since'] = lastSyncTime.toIso8601String();
      }

      final uri =
          Uri.parse('${AppConstants.baseUrl}/notifications/sync/updated')
              .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return List<Map<String, dynamic>>.from(data['notifications']);
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Batch sync operations
  Future<Map<String, dynamic>> batchSyncBookings(
      List<Map<String, dynamic>> bookings) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/bookings/sync/batch'),
        headers: headers,
        body: jsonEncode({'bookings': bookings}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      }
      return {'success': false, 'message': 'Batch sync failed'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> batchSyncNotifications(
      List<Map<String, dynamic>> notifications) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/notifications/sync/batch'),
        headers: headers,
        body: jsonEncode({'notifications': notifications}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      }
      return {'success': false, 'message': 'Batch sync failed'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Get sync status from server
  Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/sync/status'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      }
      return {'success': false, 'message': 'Failed to get sync status'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Static HTTP methods for external use
  static Future<Map<String, dynamic>> get(String endpoint,
      {Map<String, String>? headers}) async {
    try {
      await initialize();
      final authHeaders = await _getAuthHeaders();
      final allHeaders = {...authHeaders, ...?headers};

      final response =
          await _dio.get(endpoint, options: Options(headers: allHeaders));
      return response.data;
    } catch (error) {
      final appError = await _errorHandler.handleError(
        error,
        context: 'GET Request: $endpoint',
      );
      throw appError;
    }
  }

  static Future<Map<String, dynamic>> post(String endpoint, dynamic data,
      {Map<String, String>? headers}) async {
    try {
      await initialize();
      final authHeaders = await _getAuthHeaders();
      final allHeaders = {...authHeaders, ...?headers};

      final response = await _dio.post(endpoint,
          data: data, options: Options(headers: allHeaders));
      return response.data;
    } catch (error) {
      final appError = await _errorHandler.handleError(
        error,
        context: 'POST Request: $endpoint',
      );
      throw appError;
    }
  }

  static Future<Map<String, dynamic>> put(String endpoint, dynamic data,
      {Map<String, String>? headers}) async {
    try {
      await initialize();
      final authHeaders = await _getAuthHeaders();
      final allHeaders = {...authHeaders, ...?headers};

      final response = await _dio.put(endpoint,
          data: data, options: Options(headers: allHeaders));
      return response.data;
    } catch (error) {
      final appError = await _errorHandler.handleError(
        error,
        context: 'PUT Request: $endpoint',
      );
      throw appError;
    }
  }

  static Future<Map<String, dynamic>> delete(String endpoint,
      {Map<String, String>? headers}) async {
    try {
      await initialize();
      final authHeaders = await _getAuthHeaders();
      final allHeaders = {...authHeaders, ...?headers};

      final response =
          await _dio.delete(endpoint, options: Options(headers: allHeaders));
      return response.data;
    } catch (error) {
      final appError = await _errorHandler.handleError(
        error,
        context: 'DELETE Request: $endpoint',
      );
      throw appError;
    }
  }

  static Future<void> logoutLocal() async {
    await removeToken();
  }
}
