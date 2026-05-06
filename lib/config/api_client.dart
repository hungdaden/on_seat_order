import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiClient {
  static const String _devBaseUrl = 'http://localhost:8080';

  static String get baseUrl {
    if (kIsWeb) {
      final origin = Uri.base.origin;
      if (origin.contains(':3000') || origin.contains(':3001')) {
        return _devBaseUrl;
      }
      return origin;
    }
    return _devBaseUrl;
  }

  static String? _authToken;

  static void setToken(String? token) {
    _authToken = token;
  }

  static String? get token => _authToken;

  static Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  static Future<dynamic> get(String path) async {
    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, response.body);
  }

  static Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, response.body);
  }

  static Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, response.body);
  }

  static Future<dynamic> delete(String path) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, response.body);
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String body;

  ApiException(this.statusCode, this.body);

  String get message {
    try {
      final decoded = jsonDecode(body);
      return decoded['error'] ?? 'Unknown error';
    } catch (_) {
      return body;
    }
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
