import 'dart:async';

import 'package:dio/dio.dart';

class ApiConfig {
  const ApiConfig({
    required this.useNetwork,
    required this.baseUrl,
    required this.googleIdToken,
  });

  final bool useNetwork;
  final String baseUrl;
  final String googleIdToken;
}

class PhodexApiClient {
  PhodexApiClient(this.config)
    : _dio = Dio(
        BaseOptions(
          baseUrl: config.baseUrl,
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 12),
          headers: const {'Accept': 'application/json'},
        ),
      );

  final ApiConfig config;
  final Dio _dio;
  String? _accessToken;
  Future<String>? _loginFuture;

  Dio get dio => _dio;

  Future<String> getAccessToken() {
    final token = _accessToken;
    if (token != null && token.isNotEmpty) {
      return Future.value(token);
    }

    _loginFuture ??= _login();
    return _loginFuture!;
  }

  Future<Map<String, dynamic>> getJson(String path) async {
    final response = await _dio.get<Map<String, dynamic>>(
      path,
      options: await _authOptions(),
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      path,
      data: body ?? <String, dynamic>{},
      options: await _authOptions(),
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<Response<ResponseBody>> getStream(String path) async {
    final options = await _authOptions();
    return _dio.get<ResponseBody>(
      path,
      options: options.copyWith(
        responseType: ResponseType.stream,
        receiveTimeout: Duration.zero,
        headers: {
          ...?options.headers,
          'Accept': 'text/event-stream',
          'Cache-Control': 'no-cache',
        },
      ),
    );
  }

  Future<Options> _authOptions() async {
    final token = await getAccessToken();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<String> _login() async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/google',
        data: {'id_token': config.googleIdToken},
      );
      final token = response.data?['access_token'] as String?;
      if (token == null || token.isEmpty) {
        throw StateError('Backend auth response did not include access_token');
      }
      _accessToken = token;
      return token;
    } finally {
      _loginFuture = null;
    }
  }
}
