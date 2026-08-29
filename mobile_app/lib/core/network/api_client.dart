import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
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
    };
    if (includeContentType) {
      headers['Content-Type'] = 'application/json';
    }
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode == 401) {
      onUnauthorized?.call();
      throw Exception('Session expired. Please sign in again.');
    }
    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data['data'];
    } else {
      throw Exception(data['message'] ?? 'Request failed (${response.statusCode})');
    }
  }

  static Future<dynamic> get(String endpoint) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _headers();
    final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 20));
    return _handleResponse(response);
  }

  static Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _headers();
    final response = await http
        .post(url, headers: headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 20));
    return _handleResponse(response);
  }

  static Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _headers();
    final response = await http
        .put(url, headers: headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 20));
    return _handleResponse(response);
  }

  static Future<dynamic> patch(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _headers();
    final response = await http
        .patch(url, headers: headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 20));
    return _handleResponse(response);
  }

  static Future<dynamic> delete(String endpoint) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _headers();
    final response = await http.delete(url, headers: headers).timeout(const Duration(seconds: 20));
    return _handleResponse(response);
  }

  /// Upload a file as multipart form data.
  /// [fileBytes] — raw bytes of the file.
  /// [fileName] — original file name with extension (e.g. "deed.pdf").
  /// [fieldName] — multipart field name expected by the backend (default: "document").
  /// [extraFields] — additional text fields to include in the request.
  static Future<dynamic> uploadFile(
    String endpoint, {
    required Uint8List fileBytes,
    required String fileName,
    String fieldName = 'document',
    Map<String, String> extraFields = const {},
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final authHeaders = await _headers(includeContentType: false);

    final request = http.MultipartRequest('POST', url)
      ..headers.addAll(authHeaders)
      ..files.add(http.MultipartFile.fromBytes(fieldName, fileBytes, filename: fileName));

    for (final entry in extraFields.entries) {
      request.fields[entry.key] = entry.value;
    }

    final streamed = await request.send().timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamed);
    return _handleResponse(response);
  }
}
