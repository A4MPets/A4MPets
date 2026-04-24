import 'dart:async';

import 'package:http/http.dart' as http;

import 'backend_api_client.dart';

class SyncApiGateway {
  SyncApiGateway({
    required BackendApiClient apiClient,
    this.timeout = const Duration(seconds: 5),
  }) : _apiClient = apiClient;

  final BackendApiClient _apiClient;
  final Duration timeout;

  List<String> get baseUrls => _apiClient.baseUrls;

  Future<http.Response?> post({
    required String path,
    required Object body,
    String? bearerToken,
  }) {
    return _apiClient.postWithFallback(
      path,
      body: body,
      bearerToken: bearerToken,
      timeout: timeout,
    );
  }

  Future<http.Response?> get({required String path, String? bearerToken}) {
    return _apiClient.getWithFallback(
      path,
      bearerToken: bearerToken,
      timeout: timeout,
    );
  }

  Future<http.Response?> put({
    required String path,
    required Object body,
    String? bearerToken,
  }) {
    return _apiClient.putWithFallback(
      path,
      body: body,
      bearerToken: bearerToken,
      timeout: timeout,
    );
  }
}
