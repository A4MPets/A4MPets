import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class BackendApiClient {
  BackendApiClient({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  static const String configuredApiBaseUrl = String.fromEnvironment(
    'A4M_API_BASE_URL',
    defaultValue: 'http://localhost:8000/api',
  );

  static String? workingBaseUrl;

  final http.Client _httpClient;

  List<String> get baseUrls {
    final List<String> urls = <String>[
      ..._splitConfiguredBaseUrls(configuredApiBaseUrl),
      'http://127.0.0.1:8000/api',
      if (!kIsWeb) 'http://10.0.2.2:8000/api',
    ];

    final Set<String> seen = <String>{};
    return urls.where((String url) => seen.add(url)).toList(growable: false);
  }

  List<String> _splitConfiguredBaseUrls(String rawValue) {
    return rawValue
        .split(RegExp(r'[\s,;]+'))
        .map((String value) => value.trim())
        .where((String value) => value.isNotEmpty)
        .toList(growable: false);
  }

  Map<String, String> jsonHeaders({String? bearerToken}) {
    final Map<String, String> headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (bearerToken != null && bearerToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $bearerToken';
    }

    return headers;
  }

  Future<http.Response?> postWithFallback(
    String path, {
    required Object body,
    String? bearerToken,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    http.Response? lastServerError;
    for (final String baseUrl in baseUrls) {
      try {
        final http.Response response = await _httpClient
            .post(
              Uri.parse('$baseUrl$path'),
              headers: jsonHeaders(bearerToken: bearerToken),
              body: jsonEncode(body),
            )
            .timeout(timeout);

        if (response.statusCode < 500) {
          workingBaseUrl = baseUrl;
          return response;
        }
        lastServerError = response;
      } catch (_) {
        // Try the next known local endpoint.
      }
    }

    return lastServerError;
  }

  Future<http.Response?> getWithFallback(
    String path, {
    String? bearerToken,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    http.Response? lastServerError;
    for (final String baseUrl in baseUrls) {
      try {
        final http.Response response = await _httpClient
            .get(
              Uri.parse('$baseUrl$path'),
              headers: jsonHeaders(bearerToken: bearerToken),
            )
            .timeout(timeout);

        if (response.statusCode < 500) {
          workingBaseUrl = baseUrl;
          return response;
        }
        lastServerError = response;
      } catch (_) {
        // Try the next known local endpoint.
      }
    }

    return lastServerError;
  }

  Future<http.Response?> putWithFallback(
    String path, {
    required Object body,
    String? bearerToken,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    http.Response? lastServerError;
    for (final String baseUrl in baseUrls) {
      try {
        final http.Response response = await _httpClient
            .put(
              Uri.parse('$baseUrl$path'),
              headers: jsonHeaders(bearerToken: bearerToken),
              body: jsonEncode(body),
            )
            .timeout(timeout);

        if (response.statusCode < 500) {
          workingBaseUrl = baseUrl;
          return response;
        }
        lastServerError = response;
      } catch (_) {
        // Try the next known local endpoint.
      }
    }

    return lastServerError;
  }

  Future<http.Response?> deleteWithFallback(
    String path, {
    String? bearerToken,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    http.Response? lastServerError;
    for (final String baseUrl in baseUrls) {
      try {
        final http.Response response = await _httpClient
            .delete(
              Uri.parse('$baseUrl$path'),
              headers: jsonHeaders(bearerToken: bearerToken),
            )
            .timeout(timeout);

        if (response.statusCode < 500) {
          workingBaseUrl = baseUrl;
          return response;
        }
        lastServerError = response;
      } catch (_) {
        // Try the next known local endpoint.
      }
    }

    return lastServerError;
  }
}
