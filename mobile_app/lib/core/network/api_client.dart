import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class ApiClient {
  /// Callback invoked when any request gets a 401 Unauthorized response.
  /// Set this in main.dart to trigger logout + navigate to login screen.
  static void Function()? onUnauthorized;

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<Map<String, String>> _headers({bool includeContentType = true}) async {
    final token = await getToken();
    final headers = <String, String>{
      'Accept': 'application/json',
      'x-client-platform': 'Flutter Mobile App',
      'x-device-name': 'Hometrust Mobile App',
    };
    if (includeContentType) {
      headers['Content-Type'] = 'application/json';
    }
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static dynamic _handleResponse(http.Response response, {String? endpoint}) {
    Map<String, dynamic> data;
    final body = response.body.trim();

    if (body.startsWith('{')) {
      try {
        data = jsonDecode(body) as Map<String, dynamic>;
      } catch (_) {
        data = {'message': 'Malformed JSON server response'};
      }
    } else if (body.startsWith('[')) {
      try {
        return jsonDecode(body);
      } catch (_) {
        data = {'message': 'Malformed list response'};
      }
    } else {
      // Non-JSON response (e.g. HTML error page or plain text)
      data = {'message': 'Server error (${response.statusCode}). Please check your connection or try again.'};
    }

    if (response.statusCode == 401) {
      final isAuthEndpoint = endpoint != null && endpoint.startsWith('/auth/');
      if (!isAuthEndpoint) {
        onUnauthorized?.call();
      }
      throw Exception(data['message'] ?? 'Invalid credentials or session expired.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data.containsKey('data') ? data['data'] : data;
    } else {
      throw Exception(data['message'] ?? 'Request failed (${response.statusCode})');
    }
  }

  /// Wakes up the Render backend if it returned a non-JSON response (cold start).
  static Future<void> _wakeUpBackend() async {
    try {
      await http.get(
        Uri.parse('https://estateverify-app.onrender.com/health'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));
      // Wait extra second for boot to stabilize
      await Future.delayed(const Duration(seconds: 2));
    } catch (_) {}
  }

  static bool _isHtmlResponse(String body) {
    final t = body.trim().toLowerCase();
    return t.startsWith('<!doctype') || t.startsWith('<html');
  }

  static Future<dynamic> get(String endpoint) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _headers();
    var response = await http.get(url, headers: headers).timeout(const Duration(seconds: 30));
    if (_isHtmlResponse(response.body)) {
      await _wakeUpBackend();
      response = await http.get(url, headers: headers).timeout(const Duration(seconds: 30));
    }
    return _handleResponse(response, endpoint: endpoint);
  }

  static Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _headers();
    var response = await http
        .post(url, headers: headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 30));
    if (_isHtmlResponse(response.body)) {
      await _wakeUpBackend();
      response = await http
          .post(url, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 30));
    }
    return _handleResponse(response, endpoint: endpoint);
  }

  static Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _headers();
    var response = await http
        .put(url, headers: headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 30));
    if (_isHtmlResponse(response.body)) {
      await _wakeUpBackend();
      response = await http
          .put(url, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 30));
    }
    return _handleResponse(response, endpoint: endpoint);
  }

  static Future<dynamic> patch(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _headers();
    var response = await http
        .patch(url, headers: headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 30));
    if (_isHtmlResponse(response.body)) {
      await _wakeUpBackend();
      response = await http
          .patch(url, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 30));
    }
    return _handleResponse(response);
  }

  static Future<dynamic> delete(String endpoint) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _headers();
    var response = await http.delete(url, headers: headers).timeout(const Duration(seconds: 30));
    if (_isHtmlResponse(response.body)) {
      await _wakeUpBackend();
      response = await http.delete(url, headers: headers).timeout(const Duration(seconds: 30));
    }
    return _handleResponse(response);
  }

  /// Upload a file via backend multipart endpoint (authenticated, Supabase service-role key).
  /// Retries once if Render backend was cold-starting.
  static Future<dynamic> uploadFile(
    String endpoint, {
    required Uint8List fileBytes,
    required String fileName,
    String fieldName = 'file',
    Map<String, String> extraFields = const {},
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final authHeaders = await _headers(includeContentType: false);

    MediaType? mediaType;
    final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
    if (['jpg', 'jpeg'].contains(ext)) {
      mediaType = MediaType('image', 'jpeg');
    } else if (ext == 'png') {
      mediaType = MediaType('image', 'png');
    } else if (ext == 'webp') {
      mediaType = MediaType('image', 'webp');
    } else if (ext == 'gif') {
      mediaType = MediaType('image', 'gif');
    } else if (ext == 'mp4' || ext == 'm4v') {
      mediaType = MediaType('video', 'mp4');
    } else if (ext == 'mov') {
      mediaType = MediaType('video', 'quicktime');
    } else if (ext == 'mp3') {
      mediaType = MediaType('audio', 'mpeg');
    } else if (ext == 'wav') {
      mediaType = MediaType('audio', 'wav');
    } else if (ext == 'pdf') {
      mediaType = MediaType('application', 'pdf');
    }

    http.MultipartRequest _buildRequest() {
      final req = http.MultipartRequest('POST', url)
        ..headers.addAll(authHeaders)
        ..files.add(http.MultipartFile.fromBytes(
          fieldName,
          fileBytes,
          filename: fileName,
          contentType: mediaType,
        ));
      for (final entry in extraFields.entries) {
        req.fields[entry.key] = entry.value;
      }
      return req;
    }

    var streamed = await _buildRequest().send().timeout(const Duration(seconds: 120));
    var response = await http.Response.fromStream(streamed);

    // If Render returned an HTML cold-start page, wake it up and retry once
    if (_isHtmlResponse(response.body)) {
      await _wakeUpBackend();
      streamed = await _buildRequest().send().timeout(const Duration(seconds: 120));
      response = await http.Response.fromStream(streamed);
    }

    return _handleResponse(response, endpoint: endpoint);
  }
}
