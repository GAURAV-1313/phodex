import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mobile/core/providers/repository_providers.dart';

final authControllerProvider = AsyncNotifierProvider<AuthController, bool>(
  AuthController.new,
);

/// Why a sign-in attempt didn't produce a session — so the sign-in screen
/// can say something specific ("you cancelled" vs. "your runtime is down")
/// instead of one generic "couldn't sign in" for every cause.
enum AuthFailure {
  cancelled,
  noNetwork,
  unsupportedPlatform,
  runtimeUnreachable,
  unknown;

  static AuthFailure fromError(Object error) {
    if (error is GoogleSignInException) {
      return error.code == GoogleSignInExceptionCode.canceled
          ? AuthFailure.cancelled
          : AuthFailure.unknown;
    }
    if (error is StateError) {
      return error.message.toLowerCase().contains('cancelled')
          ? AuthFailure.cancelled
          : AuthFailure.unknown;
    }
    if (error is UnsupportedError) return AuthFailure.unsupportedPlatform;
    if (error is TimeoutException) return AuthFailure.cancelled;
    if (error is DioException) {
      return switch (error.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.connectionError => AuthFailure.runtimeUnreachable,
        DioExceptionType.unknown => AuthFailure.noNetwork,
        DioExceptionType.badResponse ||
        DioExceptionType.badCertificate ||
        DioExceptionType.cancel => AuthFailure.unknown,
      };
    }
    return AuthFailure.unknown;
  }
}

extension AuthStateFailure on AsyncValue<bool> {
  /// The classified failure behind an errored auth state, or null when the
  /// last attempt didn't fail.
  AuthFailure? get failure {
    final error = this.error;
    return hasError && error != null ? AuthFailure.fromError(error) : null;
  }
}

/// Owns native Google authentication and the short-lived Phodex API session.
/// Native credentials are not persisted by the app; the API JWT stays in memory.
///
/// State is `bool isSignedIn`, not `void` — a `void` state means the very
/// first (harmless, automatic) `build()` settling from loading to data is
/// structurally identical to a real `signIn()` success, so anything
/// listening for "the user signed in" via `next is AsyncData<void>` fires
/// on every app launch whether or not sign-in ever happened.
///
/// The initial `build()` (session restore) is the only time the state has
/// no value at all; every later transition keeps the previous value, which
/// is how the router tells "still bootstrapping" from "sign-in in flight".
class AuthController extends AsyncNotifier<bool> {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _events;
  Completer<String>? _tokenCompleter;
  bool _initialized = false;

  @override
  Future<bool> build() async {
    ref.onDispose(() => _events?.cancel());
    final config = ref.read(apiConfigProvider);
    if (!config.useNetwork) return false;
    // Restores a previously-signed-in session (validated against the
    // backend, not trusted blindly) so the app doesn't force a fresh
    // Google sign-in on every cold start. While this resolves, the router
    // holds the splash screen.
    return ref.read(apiClientProvider).tryRestoreSession();
  }

  Future<void> signIn() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final config = ref.read(apiConfigProvider);
      if (!config.useNetwork) return true;

      final idToken = config.googleIdToken.trim().isNotEmpty
          ? config.googleIdToken
          : await _authenticateNatively(
              iosClientId: config.googleIosClientId,
              serverClientId: config.googleServerClientId,
            );
      await ref.read(apiClientProvider).loginWithGoogleIdToken(idToken);
      return true;
    });
  }

  /// Signs into the runtime's public demo account (Phodex Cloud only — the
  /// sign-in screen only offers this when the runtime reports it).
  Future<void> signInAsDemo() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).signInAsDemo();
      return true;
    });
  }

  Future<void> signOut() async {
    ref.read(apiClientProvider).clearSession();
    if (ref.read(apiConfigProvider).useNetwork && _initialized) {
      await _googleSignIn.signOut();
    }
    state = const AsyncData(false);
  }

  /// Ends the Phodex API session without touching the Google account or
  /// onboarding progress — used when the backend address changes (a token
  /// issued by the old backend is meaningless to the new one), so the user
  /// only has to sign in again, not redo setup.
  void endSession() {
    ref.read(apiClientProvider).clearSession();
    state = const AsyncData(false);
  }

  Future<String> _authenticateNatively({
    required String iosClientId,
    required String serverClientId,
  }) async {
    if (!_initialized) {
      await _googleSignIn.initialize(
        clientId: iosClientId.isEmpty ? null : iosClientId,
        serverClientId: serverClientId.isEmpty ? null : serverClientId,
      );
      _events = _googleSignIn.authenticationEvents.listen(
        (event) {
          if (event is GoogleSignInAuthenticationEventSignIn) {
            final token = event.user.authentication.idToken;
            if (token != null && token.isNotEmpty) {
              _tokenCompleter?.complete(token);
            } else {
              _tokenCompleter?.completeError(
                StateError('Google did not return an ID token.'),
              );
            }
          }
          if (event is GoogleSignInAuthenticationEventSignOut) {
            _tokenCompleter?.completeError(
              StateError('Google sign-in was cancelled.'),
            );
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          _tokenCompleter?.completeError(error, stackTrace);
        },
      );
      _initialized = true;
    }

    if (!_googleSignIn.supportsAuthenticate()) {
      throw UnsupportedError(
        'This platform needs its Google Sign-In SDK button configuration.',
      );
    }

    _tokenCompleter = Completer<String>();
    await _googleSignIn.authenticate();
    try {
      return await _tokenCompleter!.future.timeout(const Duration(seconds: 30));
    } finally {
      _tokenCompleter = null;
    }
  }
}
