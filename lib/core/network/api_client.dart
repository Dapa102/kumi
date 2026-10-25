import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class ApiException implements Exception {
  ApiException(this.statusCode, this.code, this.message, {this.fields});

  final int statusCode;
  final String code;
  final String message;
  final Map<String, String>? fields;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => 'ApiException($statusCode, $code, $message)';
}

class NetworkException implements Exception {
  const NetworkException([this.message = 'Tidak dapat terhubung ke server.']);

  final String message;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  String? _token;

  void setToken(String? token) => _token = token;

  Map<String, String> _headers() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      // Backend uses this to compute the user's local calendar day.
      'X-Timezone-Offset': '${DateTime.now().timeZoneOffset.inMinutes}',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: query);
    return _send(() => _client.get(uri, headers: _headers()));
  }

  Future<dynamic> post(String path, {Object? body}) async {
    final uri = Uri.parse('$_baseUrl$path');
    return _send(
      () => _client.post(
        uri,
        headers: _headers(),
        body: body == null ? null : jsonEncode(body),
      ),
    );
  }

  Future<dynamic> put(String path, {Object? body}) async {
    final uri = Uri.parse('$_baseUrl$path');
    return _send(
      () => _client.put(
        uri,
        headers: _headers(),
        body: body == null ? null : jsonEncode(body),
      ),
    );
  }

  Future<dynamic> patch(String path, {Object? body}) async {
    final uri = Uri.parse('$_baseUrl$path');
    return _send(
      () => _client.patch(
        uri,
        headers: _headers(),
        body: body == null ? null : jsonEncode(body),
      ),
    );
  }

  Future<dynamic> delete(String path) async {
    final uri = Uri.parse('$_baseUrl$path');
    return _send(() => _client.delete(uri, headers: _headers()));
  }

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    late http.Response response;
    try {
      response = await request().timeout(AppConfig.requestTimeout);
    } catch (_) {
      throw const NetworkException();
    }

    if (response.statusCode == 204) return null;

    dynamic decoded;
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = null;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    final detail = decoded is Map<String, dynamic> ? decoded['detail'] : null;
    if (detail is Map<String, dynamic>) {
      final rawFields = detail['fields'];
      final fields = rawFields is Map
          ? rawFields.map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            )
          : null;
      throw ApiException(
        response.statusCode,
        (detail['code'] ?? 'ERROR').toString(),
        (detail['message'] ?? 'Terjadi kesalahan.').toString(),
        fields: fields,
      );
    }

    throw ApiException(
      response.statusCode,
      'ERROR',
      'Terjadi kesalahan. Coba lagi.',
    );
  }
}
