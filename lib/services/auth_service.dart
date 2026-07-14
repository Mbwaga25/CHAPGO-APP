import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api;
  ApiService get api => _api;
  static const String _tokenKey = 'chapgo_token';
  static const String _userKey = 'chapgo_user';

  AuthService(this._api);

  Future<void> saveSession(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, user.token);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    _api.setToken(user.token);
  }

  Future<User?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final userJson = prefs.getString(_userKey);
    if (token != null && userJson != null) {
      final user = User.fromJson(jsonDecode(userJson));
      _api.setToken(token);
      return user;
    }
    return null;
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    _api.setToken(null);
  }

  Future<User> stationOtpLogin(String phone, String code) async {
    final result = await _api.post('/auth/login/otp', body: {
      'phone': phone,
      'code': code,
      'user_type': 'station_operator',
    });
    final user = User.fromStationJson(result['user'], result['token']);
    await saveSession(user);
    return user;
  }

  Future<User> driverOtpLogin(String phone, String code) async {
    final result = await _api.post('/auth/login/otp', body: {
      'phone': phone,
      'code': code,
      'user_type': 'driver',
    });
    final user = User.fromDriverJson(result['user'], result['token']);
    await saveSession(user);
    return user;
  }

  Future<User> stationPasswordLogin(String phone, String password) async {
    final result = await _api.post('/auth/login/station-operator', body: {
      'phone': phone,
      'password': password,
    });
    final user = User.fromStationJson(result['user'], result['token']);
    await saveSession(user);
    return user;
  }

  Future<User> driverPasswordLogin(String phone, String password) async {
    final result = await _api.post('/auth/login/driver-password', body: {
      'phone': phone,
      'password': password,
    });
    final user = User.fromDriverJson(result['user'], result['token']);
    await saveSession(user);
    return user;
  }

  Future<User> adminLogin(String email, String password) async {
    final result = await _api.post('/auth/login/admin', body: {
      'email': email,
      'password': password,
    });
    final user = User.fromAdminJson(result['user'], result['token']);
    await saveSession(user);
    return user;
  }

  Future<User> unifiedLogin(String identifier, String password) async {
    final result = await _api.post('/auth/login', body: {
      'identifier': identifier,
      'password': password,
    });
    final user = User.fromUnifiedJson(result['user'], result['token']);
    await saveSession(user);
    return user;
  }

  Future<User> registerDriver({
    required String phone,
    required String password,
    required String fullName,
    required String nidaNumber,
    required String otpCode,
    required String vehiclePlate,
    required String vehicleType,
    required bool consentToDataProcessing,
  }) async {
    await _api.post('/driver/register', body: {
      'phone': phone,
      'password': password,
      'full_name': fullName,
      'nida_number': nidaNumber,
      'otp_code': otpCode,
      'vehicle_plate': vehiclePlate,
      'vehicle_type': vehicleType,
      'consent_to_data_processing': consentToDataProcessing,
    });

    final loginResult = await _api.post('/auth/login/otp', body: {
      'phone': phone,
      'code': otpCode,
      'user_type': 'driver',
    });
    final user = User.fromDriverJson(loginResult['user'], loginResult['token']);
    await saveSession(user);
    return user;
  }

  Future<void> sendOtp(String phone, {String purpose = 'login'}) async {
    await _api.post('/otp/send', body: {
      'phone': phone,
      'purpose': purpose,
    });
  }

  Future<User> updateDriverProfile({
    required String token,
    required Map<String, String> fields,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    final result = await _api.multipartRequest(
      'PUT',
      '/driver/profile',
      fields: fields,
      fileKey: 'profile_image',
      fileBytes: fileBytes,
      fileName: fileName,
    );
    // Note: unified login returned a JSON with type, role. 
    // Since we are updating, we know it's a driver.
    // Let's pass unified format. The profile payload has full_name, email, phone, etc.
    final updatedUser = User.fromUnifiedJson(result['profile'], token);
    return updatedUser;
  }

  Future<void> logout() async {
    await clearSession();
  }
}
