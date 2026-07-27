import 'dart:convert';

import 'package:http/http.dart' as http;

class CoreApiException implements Exception {
  CoreApiException({
    required this.statusCode,
    required this.message,
    this.body,
  });

  final int statusCode;
  final String message;
  final Map<String, dynamic>? body;

  @override
  String toString() => 'CoreApiException($statusCode): $message';
}

class GeneratedScheduleApiClient {
  GeneratedScheduleApiClient({
    required this.baseUrl,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _httpClient;

  Future<Map<String, dynamic>> generate({
    required Map<String, dynamic> body,
  }) {
    return _requestJson(
      method: 'POST',
      path: '/api/v1/generated-schedules:generate',
      body: body,
    );
  }

  Future<Map<String, dynamic>> getById(String generatedScheduleId) {
    return _requestJson(
      method: 'GET',
      path: '/api/v1/generated-schedules/$generatedScheduleId',
    );
  }

  Future<Map<String, dynamic>> _requestJson({
    required String method,
    required String path,
    Map<String, dynamic>? body,
  }) async {
    final uri = _buildUri(path);

    late final http.Response response;

    switch (method) {
      case 'GET':
        response = await _httpClient.get(uri, headers: _headers());
        break;
      case 'POST':
        response = await _httpClient.post(
          uri,
          headers: _headers(),
          body: jsonEncode(body ?? const <String, dynamic>{}),
        );
        break;
      default:
        throw UnsupportedError('Unsupported method: $method');
    }

    final decoded = _decodeJsonObject(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CoreApiException(
        statusCode: response.statusCode,
        message: decoded['message']?.toString() ?? 'core api request failed',
        body: decoded,
      );
    }

    return decoded;
  }

  Uri _buildUri(String path) {
    final normalizedBaseUrl = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    return Uri.parse(normalizedBaseUrl).resolve(
      path.startsWith('/') ? path.substring(1) : path,
    );
  }

  Map<String, String> _headers() {
    return const {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  Map<String, dynamic> _decodeJsonObject(http.Response response) {
    if (response.bodyBytes.isEmpty) {
      return <String, dynamic>{};
    }

    final text = utf8.decode(response.bodyBytes).trim();
    if (text.isEmpty) {
      return <String, dynamic>{};
    }

    final dynamic decoded = jsonDecode(text);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw CoreApiException(
      statusCode: response.statusCode,
      message: 'response is not a JSON object',
    );
  }
}
