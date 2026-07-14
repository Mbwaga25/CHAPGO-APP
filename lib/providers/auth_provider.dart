import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

enum AuthStatus { uninitialized, authenticated, unauthenticated, loading }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthStatus _status = AuthStatus.uninitialized;
  User? _user;
  String? _error;

  AuthProvider(this._authService) {
    _authService.api.onUnauthorized = () {
      logout();
    };
  }

  AuthStatus get status => _status;
  User? get user => _user;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  UserRole? get role => _user?.userRole;

  Future<void> tryAutoLogin() async {
    try {
      final user = await _authService.loadSession();
      if (user != null) {
        _user = user;
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> sendOtp(String phone, {String purpose = 'login'}) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();
    try {
      await _authService.sendOtp(phone, purpose: purpose);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> stationOtpLogin(String phone, String code) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _user = await _authService.stationOtpLogin(phone, code);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> driverOtpLogin(String phone, String code) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _user = await _authService.driverOtpLogin(phone, code);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> stationPasswordLogin(String phone, String password) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _user = await _authService.stationPasswordLogin(phone, password);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> driverPasswordLogin(String phone, String password) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _user = await _authService.driverPasswordLogin(phone, password);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> adminLogin(String email, String password) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _user = await _authService.adminLogin(email, password);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String identifier, String password) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _user = await _authService.unifiedLogin(identifier, password);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerDriver({
    required String phone,
    required String password,
    required String fullName,
    required String nidaNumber,
    required String otpCode,
    required String vehiclePlate,
    required String vehicleType,
    required bool consentToDataProcessing,
  }) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _user = await _authService.registerDriver(
        phone: phone,
        password: password,
        fullName: fullName,
        nidaNumber: nidaNumber,
        otpCode: otpCode,
        vehiclePlate: vehiclePlate,
        vehicleType: vehicleType,
        consentToDataProcessing: consentToDataProcessing,
      );
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    _error = null;
    notifyListeners();
  }

  Future<bool> updateDriverProfile({
    required Map<String, String> fields,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    if (_user == null) return false;
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();
    try {
      final updatedUser = await _authService.updateDriverProfile(
        token: _user!.token,
        fields: fields,
        fileBytes: fileBytes,
        fileName: fileName,
      );
      _user = updatedUser;
      await _authService.saveSession(_user!);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.authenticated;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
