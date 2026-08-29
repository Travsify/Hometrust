import 'package:flutter/foundation.dart';

class ApiConstants {
  // Live Cloud Production API on Render
  static const String _productionUrl = 'https://estateverify-app.onrender.com/api/v1';
  static const String _localUrl = 'http://localhost:5000/api/v1';

  // Toggle between live production URL and local development
  static String get baseUrl {
    // In production or mobile physical testing, use live Render URL:
    return _productionUrl;
  }

  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authMe = '/auth/me';

  static const String properties = '/properties';
  static const String projects = '/projects';
  static const String developers = '/developers';
  static const String verifications = '/verifications';
  static const String legal = '/legal';
  static const String purchases = '/purchases';
  static const String payments = '/payments';
  static const String inspections = '/inspections';
  static const String notifications = '/notifications';
}
