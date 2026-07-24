import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mobile/core/providers/repository_providers.dart';

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);

/// Owns native Google authentication and the short-lived Phodex API session.
/// Native credentials are not persisted by the app; the API JWT stays in memory.
class AuthController extends AsyncNotifier<void> {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _events;
  Completer<String>? _tokenCompleter;
  bool _initialized = false;

  @override
  Future<void> build() async {
    ref.onDispose(() => _events?.cancel());
  }

  Future<void> signIn() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final config = ref.read(apiConfigProvider);
      if (!config.useNetwork) return;

      final idToken = config.googleIdToken.trim().isNotEmpty
          ? config.googleIdToken
          : await _authenticateNatively(
              iosClientId: config.googleIosClientId,
              serverClientId: config.googleServerClientId,
            );
      await ref.read(apiClientProvider).loginWithGoogleIdToken(idToken);
    });
  }

  Future<void> signOut() async {
    ref.read(apiClientProvider).clearSession();
    if (ref.read(apiConfigProvider).useNetwork && _initialized) {
      await _googleSignIn.signOut();
    }
    state = const AsyncData(null);
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
