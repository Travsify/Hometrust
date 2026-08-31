import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../core/network/api_client.dart';
import '../core/network/socket_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;
  final LocalAuthentication _localAuth = LocalAuthentication();

  UserModel? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isDeveloperMode => _user?.role == 'DEVELOPER';

  void toggleDeveloperMode() {
    // Mode toggling is disabled by platform policy.
    // Buyers strictly remain in Buyer Portal; Developers strictly remain in Developer Portal.
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    if (_token != null) {
      try {
        final userData = await ApiClient.get('/auth/me');
        _user = UserModel.fromJson(userData);
        if (_user != null) {
          SocketService.instance.connect(
            userId: _user!.id,
            userName: '${_user!.firstName} ${_user!.lastName}'.trim(),
          );
          _syncOneSignalUser();
        }
      } catch (e) {
        await logout();
      }
    }
    notifyListeners();
  }

  void _syncOneSignalUser() {
    if (_user != null && _user!.id.isNotEmpty) {
      try {
        OneSignal.login(_user!.id);
        if (_user!.email.isNotEmpty) {
          OneSignal.User.addEmail(_user!.email);
        }
      } catch (e) {
        debugPrint('[ONESIGNAL LOGIN ERR] $e');
      }
    }
  }

  Future<void> logout() async {
    _user = null;
    _token = null;
    SocketService.instance.disconnect();
    try {
      OneSignal.logout();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    notifyListeners();
  }

  /// 1. Send OTP to Email (via Resend)
  Future<bool> sendEmailOtp(String email, {String purpose = 'REGISTRATION_EMAIL'}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await ApiClient.post('/auth/otp/send-email', {
        'email': email.trim(),
        'purpose': purpose,
      });
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

  /// 2. Verify Email OTP
  Future<String?> verifyEmailOtp(String email, String code, {String purpose = 'REGISTRATION_EMAIL'}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiClient.post('/auth/otp/verify-email', {
        'email': email.trim(),
        'code': code.trim(),
        'purpose': purpose,
      });
      _isLoading = false;
      notifyListeners();
      return res['verificationToken'] as String? ?? 'verified';
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  /// 3. Send OTP to Phone (via Twilio)
  Future<bool> sendPhoneOtp(String phone, {String purpose = 'REGISTRATION_PHONE'}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await ApiClient.post('/auth/otp/send-phone', {
        'phone': phone.trim(),
        'purpose': purpose,
      });
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

  /// 4. Verify Phone OTP
  Future<String?> verifyPhoneOtp(String phone, String code, {String purpose = 'REGISTRATION_PHONE'}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiClient.post('/auth/otp/verify-phone', {
        'phone': phone.trim(),
        'code': code.trim(),
        'purpose': purpose,
      });
      _isLoading = false;
      notifyListeners();
      return res['verificationToken'] as String? ?? 'verified';
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  /// 5. Initial Login Request (Dispatches 2FA OTP to Email or SMS depending on input)
  Future<Map<String, dynamic>> login(String identifier, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cleanIdentifier = identifier.trim();
      final res = await ApiClient.post('/auth/login', {
        'identifier': cleanIdentifier,
        'email': cleanIdentifier,
        'password': password,
      });

      _isLoading = false;
      notifyListeners();

      // Check if 2FA Challenge returned
      if (res != null && res['requires2FA'] == true) {
        return {
          'success': true,
          'requires2FA': true,
          'twoFactorToken': res['twoFactorToken'],
          'channel': res['channel'] ?? (cleanIdentifier.contains('@') ? 'EMAIL' : 'SMS'),
          'email': res['email'],
          'phone': res['phone'],
          'identifier': cleanIdentifier,
          'maskedDestination': res['maskedDestination'],
          'message': res['message'],
        };
      }

      // If direct login token returned
      if (res != null && res['token'] != null) {
        _token = res['token'];
        _user = UserModel.fromJson(res['user']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        await prefs.setString('saved_email', cleanIdentifier);
        if (_user != null) {
          SocketService.instance.connect(
            userId: _user!.id,
            userName: '${_user!.firstName} ${_user!.lastName}'.trim(),
          );
          _syncOneSignalUser();
        }
        notifyListeners();
        return {'success': true, 'requires2FA': false};
      }

      return {'success': false, 'message': 'Unknown login response'};
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return {'success': false, 'message': _errorMessage};
    }
  }

  /// 6. Verify 2FA OTP to complete login
  Future<bool> verifyLogin2FA({
    required String twoFactorToken,
    required String code,
    String? emailForBiometrics,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiClient.post('/auth/login-2fa/verify', {
        'twoFactorToken': twoFactorToken,
        'code': code.trim(),
      });

      _token = res['token'];
      _user = UserModel.fromJson(res['user']);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
      if (emailForBiometrics != null) {
        await prefs.setString('saved_email', emailForBiometrics);
      }
      await prefs.setString('biometric_auth_token', _token!);
      if (_user != null) {
        SocketService.instance.connect(
          userId: _user!.id,
          userName: '${_user!.firstName} ${_user!.lastName}'.trim(),
        );
        _syncOneSignalUser();
      }

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

  /// 7. Biometrics Support (Fingerprint & Face ID)
  Future<bool> isBiometricsAvailable() async {
    try {
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheckBiometrics && isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isBiometricsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('biometrics_enabled') ?? false;
  }

  Future<void> setBiometricsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometrics_enabled', enabled);
    notifyListeners();
  }

  Future<bool> biometricLogin() async {
    try {
      final available = await isBiometricsAvailable();
      if (!available) return false;

      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('biometric_auth_token');
      if (savedToken == null || savedToken.isEmpty) return false;

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Authenticate with Fingerprint or Face ID to access your Hometrust account',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );

      if (didAuthenticate) {
        _token = savedToken;
        await prefs.setString('auth_token', _token!);
        final userData = await ApiClient.get('/auth/me');
        _user = UserModel.fromJson(userData);
        if (_user != null) {
          SocketService.instance.connect(
            userId: _user!.id,
            userName: '${_user!.firstName} ${_user!.lastName}'.trim(),
          );
          _syncOneSignalUser();
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[BIOMETRIC AUTH ERROR] $e');
      return false;
    }
  }

  /// 8. Final Registration
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
      await prefs.setString('biometric_auth_token', _token!);
      await prefs.setString('saved_email', email.trim());
      if (_user != null) {
        _syncOneSignalUser();
      }

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

  bool get hasTransactionPin => _user?.hasTransactionPin == true;

  /// Setup a 6-digit payment PIN
  Future<bool> setupTransactionPin(String pin) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiClient.post('/auth/pin/setup', {'pin': pin.trim()});
      await refreshUser();
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

  /// Change 6-digit payment PIN
  Future<bool> changeTransactionPin({
    String? currentPin,
    String? currentPassword,
    required String newPin,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await ApiClient.post('/auth/pin/change', {
        if (currentPin != null) 'currentPin': currentPin.trim(),
        if (currentPassword != null) 'currentPassword': currentPassword,
        'newPin': newPin.trim(),
      });
      await refreshUser();
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

  /// Verify 6-digit payment PIN
  Future<bool> verifyTransactionPin(String pin) async {
    try {
      final res = await ApiClient.post('/auth/pin/verify', {'pin': pin.trim()});
      return res != null;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Authenticate for transactions with Device Biometrics (Fingerprint / Face ID)
  Future<bool> authenticateTransactionWithBiometrics({String reason = 'Confirm transaction with biometrics'}) async {
    try {
      final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

      if (!canAuthenticate) return false;

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      return didAuthenticate;
    } catch (e) {
      debugPrint('[BIOMETRIC TRANSACTION ERROR] $e');
      return false;
    }
  }

  Future<void> refreshUser() async {
    if (_token != null) {
      try {
        final userData = await ApiClient.get('/auth/me');
        _user = UserModel.fromJson(userData);
        _syncOneSignalUser();
        notifyListeners();
      } catch (_) {}
    }
  }
}
