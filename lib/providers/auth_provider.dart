import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  bool _isLoggedIn = false;
  bool _isAdmin = false;
  String? _accessToken;
  String? _refreshToken;
  DateTime? _tokenExpiry;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  bool get isAdmin => _isAdmin;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString('access_token');
      _refreshToken = prefs.getString('refresh_token');
      final userType = prefs.getString('user_type');
      final tokenExpiryString = prefs.getString('token_expiry');

      if (tokenExpiryString != null) {
        _tokenExpiry = DateTime.parse(tokenExpiryString);
      }

      if (_accessToken != null && _refreshToken != null && userType != null) {
        // Check if token is expired or about to expire (within 5 minutes)
        if (_tokenExpiry != null &&
            _tokenExpiry!.isBefore(DateTime.now().add(const Duration(minutes: 5)))) {
          // Try to refresh token
          final refreshResult = await _refreshAccessToken();
          if (!refreshResult) {
            await logout();
            return;
          }
        }

        if (userType == 'admin') {
          _isLoggedIn = true;
          _isAdmin = true;
        } else {
          final user = await ApiService.getProfile();
          if (user != null) {
            _user = user;
            _isLoggedIn = true;
            _isAdmin = false;
          } else {
            await logout();
          }
        }
      }
    } catch (e) {
      print('Error checking auth status: $e');
      await logout();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> _refreshAccessToken() async {
    try {
      if (_refreshToken == null) return false;

      final response = await ApiService.refreshToken(_refreshToken!);
      if (response['success']) {
        await _storeTokens(
          response['accessToken'],
          response['refreshToken'],
        );
        return true;
      }
      return false;
    } catch (e) {
      print('Error refreshing token: $e');
      return false;
    }
  }

  Future<void> _storeTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();

    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _tokenExpiry = DateTime.now()
        .add(const Duration(minutes: 15)); // Access token expires in 15 minutes

    // Store in SharedPreferences (for AuthProvider)
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
    await prefs.setString('token_expiry', _tokenExpiry!.toIso8601String());
    
    // Also store in ApiService's secure storage for API calls
    await ApiService.saveToken(accessToken);
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String address,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await ApiService.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
        address: address,
      );

      if (result['success']) {
        _user = UserModel.fromJson(result['user']);
        _isLoggedIn = true;
        _isAdmin = false;

        // Store tokens
        await _storeTokens(
          result['accessToken'],
          result['refreshToken'],
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_type', 'user');
        await ApiService.saveUserType('user');
      }

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Registration failed: $e'};
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await ApiService.login(
        email: email,
        password: password,
      );

      if (result['success']) {
        _user = UserModel.fromJson(result['user']);
        _isLoggedIn = true;
        _isAdmin = false;

        // Store tokens
        await _storeTokens(
          result['accessToken'],
          result['refreshToken'],
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_type', 'user');
        await ApiService.saveUserType('user');
      }

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Login failed: $e'};
    }
  }

  Future<Map<String, dynamic>> adminLogin({
    required String username,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await ApiService.adminLogin(
        username: username,
        password: password,
      );

      if (result['success']) {
        _isLoggedIn = true;
        _isAdmin = true;

        // Store tokens
        await _storeTokens(
          result['accessToken'],
          result['refreshToken'],
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_type', 'admin');
        await ApiService.saveUserType('admin');
      }

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Admin login failed: $e'};
    }
  }

  Future<void> logout() async {
    try {
      // Call logout API with refresh token
      if (_refreshToken != null) {
        await ApiService.logout(_refreshToken!);
      }
    } catch (e) {
      print('Error during logout API call: $e');
    }

    // Clear local state and storage
    _user = null;
    _isLoggedIn = false;
    _isAdmin = false;
    _accessToken = null;
    _refreshToken = null;
    _tokenExpiry = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('token_expiry');
    await prefs.remove('user_type');

    // Also clear ApiService tokens
    await ApiService.removeToken();

    notifyListeners();
  }

  // Get current access token, refresh if needed
  Future<String?> getCurrentAccessToken() async {
    if (_accessToken == null || _refreshToken == null) {
      return null;
    }

    // Check if token is expired or about to expire (within 2 minutes)
    if (_tokenExpiry != null &&
        _tokenExpiry!.isBefore(DateTime.now().add(const Duration(minutes: 2)))) {
      final refreshResult = await _refreshAccessToken();
      if (!refreshResult) {
        await logout();
        return null;
      }
    }

    return _accessToken;
  }

  // Check if user has specific role/permission
  bool hasRole(String role) {
    if (_isAdmin && (role == 'admin' || role == 'super_admin')) {
      return true;
    }
    if (!_isAdmin && role == 'user') {
      return true;
    }
    return false;
  }
}
