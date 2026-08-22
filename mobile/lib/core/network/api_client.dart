import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiConfig {
  const ApiConfig({
    required this.useNetwork,
    required this.baseUrl,
    required this.googleIdToken,
    this.googleServerClientId = '',
    this.googleIosClientId = '',
  });

  final bool useNetwork;
  final String baseUrl;
  final String googleIdToken;
  final String googleServerClientId;
  final String googleIosClientId;
}

class PhodexApiClient {
  PhodexApiClient(this.config, {FlutterSecureStorage? storage})
    : _dio = Dio(
        BaseOptions(
          baseUrl: config.baseUrl,
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 12),
          headers: const {'Accept': 'application/json'},
        ),
      ),
      // Only real network mode needs a persisted session — mock/UI-only mode
      // has no real backend token to remember.
      _storage = config.useNetwork
          ? (storage ?? const FlutterSecureStorage())
          : null;

  static const _tokenStorageKey = 'phodex_access_token';

  final ApiConfig config;
  final Dio _dio;
  final FlutterSecureStorage? _storage;
  String? _accessToken;
  Future<String>? _loginFuture;

  Dio get dio => _dio;

  String get baseUrl => _dio.options.baseUrl;

  /// Repoints this client at a different backend without losing the current
  /// session — used when the user pairs with (or switches) a desktop via the
  /// "Connect to desktop" flow.
  void updateBaseUrl(String url) {
    _dio.options.baseUrl = url;
  }

  /// Checks whether a candidate backend address is reachable, without
  /// touching this client's own configuration — used to validate a scanned
  /// or typed address before committing to it.
  static Future<bool> testConnection(String url) async {
    final probe = Dio(
      BaseOptions(
        baseUrl: url,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ),
    );
    try {
      final response = await probe.get<Map<String, dynamic>>('/health');
      return response.statusCode == 200;
    } on DioException {
      return false;
    } finally {
      probe.close();
    }
  }

  /// Attempts to restore a previously-persisted session on app startup.
  /// Validates the stored token against the backend rather than trusting it
  /// blindly — an expired or revoked token is cleared, not silently reused.
  Future<bool> tryRestoreSession() async {
    final stored = await _readPersistedToken();
    if (stored == null || stored.isEmpty) return false;

    try {
      await _dio.get<Map<String, dynamic>>(
        '/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $stored'}),
      );
      _accessToken = stored;
      return true;
    } catch (_) {
      // Any failure here — an expired/revoked token (DioException), a
      // malformed response body, or anything else — means "there is no
      // valid session to restore," never an app-level error. Restoring a
      // session is a best-effort background step on cold start, not a
      // user-initiated action, so it must always settle to a plain bool.
      await _deletePersistedToken();
      return false;
    }
  }

  // Session persistence is strictly best-effort: flutter_secure_storage
  // talks to the platform over a MethodChannel that isn't available outside
  // a real device/simulator (plain Dart tests, a misconfigured platform
  // binding, or an actual keychain/keystore hiccup would all surface here)
  // — none of that should ever be able to crash sign-in itself, so any
  // failure just means "nothing persisted this time," not a thrown error.
  Future<String?> _readPersistedToken() async {
    final storage = _storage;
    if (storage == null) return null;
    try {
      return await storage.read(key: _tokenStorageKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writePersistedToken(String token) async {
    try {
      await _storage?.write(key: _tokenStorageKey, value: token);
    } catch (_) {
      // Best-effort — see _readPersistedToken.
    }
  }

  Future<void> _deletePersistedToken() async {
    try {
      await _storage?.delete(key: _tokenStorageKey);
    } catch (_) {
      // Best-effort — see _readPersistedToken.
    }
  }

  Future<String> getAccessToken() {
    final token = _accessToken;
    if (token != null && token.isNotEmpty) {
      return Future.value(token);
    }

    _loginFuture ??= _login(config.googleIdToken);
    return _loginFuture!;
  }

  /// Exchanges a freshly issued Google ID token for an in-memory Phodex JWT.
  Future<String> loginWithGoogleIdToken(String idToken) {
    _accessToken = null;
    _loginFuture = _login(idToken);
    return _loginFuture!;
  }

  void clearSession() {
    _accessToken = null;
    _loginFuture = null;
    unawaited(_deletePersistedToken());
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

  Future<Map<String, dynamic>> putJson(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
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

  Future<String> _login(String idToken) async {
    if (idToken.trim().isEmpty) {
      throw StateError('Sign in with Google before calling the Phodex API.');
    }
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/google',
        data: {'id_token': idToken},
      );
      final token = response.data?['access_token'] as String?;
      if (token == null || token.isEmpty) {
        throw StateError('Backend auth response did not include access_token');
      }
      _accessToken = token;
      unawaited(_writePersistedToken(token));
      return token;
    } finally {
      _loginFuture = null;
    }
  }
}
