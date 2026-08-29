import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/network/api_client.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDeveloperMode = true;

  UserModel? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isDeveloperMode => _isDeveloperMode && _user?.role == 'DEVELOPER';

  void toggleDeveloperMode() {
    _isDeveloperMode = !_isDeveloperMode;
    // Persist the preference so switching back survives app restarts
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('developer_mode_active', _isDeveloperMode);
    });
    notifyListeners();
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    // Restore the last-used mode preference (defaults to true for developer accounts)
    _isDeveloperMode = prefs.getBool('developer_mode_active') ?? true;
    if (_token != null) {
      try {
        final userData = await ApiClient.get('/auth/me');
        _user = UserModel.fromJson(userData);
      } catch (e) {
        await logout();
      }
    }
    notifyListeners();
  }

  /// Clears the mode preference on logout so the next login starts fresh
  Future<void> logout() async {
    _user = null;
    _token = null;
    _isDeveloperMode = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('developer_mode_active');
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiClient.post('/auth/login', {
        'email': email.trim(),
        'password': password,
      });

      _token = res['token'];
      _user = UserModel.fromJson(res['user']);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
    String role = 'BUYER',
    Map<String, dynamic>? developerInfo,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final payload = {
        'email': email.trim(),
        'password': password,
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'phone': phone?.trim(),
        'role': role,
        if (developerInfo != null) 'developerInfo': developerInfo,
      };

      final res = await ApiClient.post('/auth/register', payload);

      _token = res['token'];
      _user = UserModel.fromJson(res['user']);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshUser() async {
    if (_token != null) {
      try {
        final userData = await ApiClient.get('/auth/me');
        _user = UserModel.fromJson(userData);
        notifyListeners();
      } catch (_) {}
    }
  }

}
