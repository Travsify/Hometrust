import 'package:flutter/foundation.dart';

class ApiConstants {
  // Use localhost on Web/Desktop, or 10.0.2.2 on Android Emulator
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api/v1';
    }
    // Default standard local endpoint
    return 'http://localhost:5000/api/v1';
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
