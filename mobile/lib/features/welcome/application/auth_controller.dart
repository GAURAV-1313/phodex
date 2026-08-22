import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mobile/core/providers/repository_providers.dart';

final authControllerProvider = AsyncNotifierProvider<AuthController, bool>(
  AuthController.new,
);

/// Owns native Google authentication and the short-lived Phodex API session.
/// Native credentials are not persisted by the app; the API JWT stays in memory.
///
/// State is `bool isSignedIn`, not `void` — a `void` state means the very
/// first (harmless, automatic) `build()` settling from loading to data is
/// structurally identical to a real `signIn()` success, so anything
/// listening for "the user signed in" via `next is AsyncData<void>` fires
/// on every app launch whether or not sign-in ever happened.
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
    // Google sign-in on every cold start. While this resolves, the Welcome
    // screen naturally shows its existing "Connecting…" loading state.
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

  Future<void> signOut() async {
    ref.read(apiClientProvider).clearSession();
    if (ref.read(apiConfigProvider).useNetwork && _initialized) {
      await _googleSignIn.signOut();
    }
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
