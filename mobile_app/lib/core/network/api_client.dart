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

  static Future<dynamic> get(String endpoint) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _headers();
    final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 20));
    return _handleResponse(response, endpoint: endpoint);
  }

  static Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _headers();
    final response = await http
        .post(url, headers: headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 20));
    return _handleResponse(response, endpoint: endpoint);
  }

  static Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _headers();
    final response = await http
        .put(url, headers: headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 20));
    return _handleResponse(response, endpoint: endpoint);
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

  /// Direct cloud upload to Supabase Storage with instant permanent CDN URL.
  static Future<Map<String, dynamic>> uploadToSupabase({
    required Uint8List fileBytes,
    required String fileName,
    String? folder,
  }) async {
    const supabaseUrl = 'https://towshylvowvmhvhzghoh.supabase.co';
    const anonKey = 'sb_publishable_-7svy3hEA47G7KLAxVV7mg_LlevL4eX';
    const bucket = 'estateverify-documents';

    final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : 'jpg';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final cleanName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final folderPath = folder ?? 'uploads/${DateTime.now().year}/${DateTime.now().month.toString().padLeft(2, '0')}';
    final storagePath = '$folderPath/${timestamp}_$cleanName';

    String mimeType = 'application/octet-stream';
    if (['jpg', 'jpeg'].contains(ext)) {
      mimeType = 'image/jpeg';
    } else if (ext == 'png') {
      mimeType = 'image/png';
    } else if (ext == 'webp') {
      mimeType = 'image/webp';
    } else if (ext == 'gif') {
      mimeType = 'image/gif';
    } else if (ext == 'pdf') {
      mimeType = 'application/pdf';
    } else if (ext == 'mp4' || ext == 'm4v') {
      mimeType = 'video/mp4';
    } else if (ext == 'mov') {
      mimeType = 'video/quicktime';
    }

    final url = Uri.parse('$supabaseUrl/storage/v1/object/$bucket/$storagePath');
    final response = await http.post(
      url,
      headers: {
        'apikey': anonKey,
        'Authorization': 'Bearer $anonKey',
        'Content-Type': mimeType,
      },
      body: fileBytes,
    ).timeout(const Duration(seconds: 45));

    if (response.statusCode == 200 || response.statusCode == 201) {
      final publicUrl = '$supabaseUrl/storage/v1/object/public/$bucket/$storagePath';
      return {
        'fileUrl': publicUrl,
        'fileName': fileName,
        'storedName': storagePath,
        'fileSize': fileBytes.length,
        'mimeType': mimeType,
      };
    } else {
      throw Exception('Supabase upload returned ${response.statusCode}');
    }
  }

  /// Upload a file as multipart form data.
  /// [fileBytes] — raw bytes of the file.
  /// [fileName] — original file name with extension (e.g. "deed.pdf").
  /// [fieldName] — multipart field name expected by the backend (default: "file").
  /// [extraFields] — additional text fields to include in the request.
  static Future<dynamic> uploadFile(
    String endpoint, {
    required Uint8List fileBytes,
    required String fileName,
    String fieldName = 'file',
    Map<String, String> extraFields = const {},
  }) async {
    // 1. Try direct Supabase Cloud upload for speed & zero proxy dependencies
    try {
      final directResult = await uploadToSupabase(
        fileBytes: fileBytes,
        fileName: fileName,
      );
      return directResult;
    } catch (_) {
      // 2. Fallback to backend /storage/upload endpoint if direct upload had issues
    }

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

    final request = http.MultipartRequest('POST', url)
      ..headers.addAll(authHeaders)
      ..files.add(http.MultipartFile.fromBytes(
        fieldName,
        fileBytes,
        filename: fileName,
        contentType: mediaType,
      ));

    for (final entry in extraFields.entries) {
      request.fields[entry.key] = entry.value;
    }

    final streamed = await request.send().timeout(const Duration(seconds: 120));
    final response = await http.Response.fromStream(streamed);
    return _handleResponse(response);
  }
}
