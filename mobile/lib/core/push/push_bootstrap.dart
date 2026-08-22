import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile/firebase_options.dart';

/// Must be a top-level (or static) function — the platform invokes this in
/// its own background isolate when a push arrives while the app isn't in
/// the foreground, so it can't close over any app state.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Nothing to do beyond letting the OS show the notification itself (FCM
  // notification-type messages are display-only unless the app is running)
  // — this exists so onBackgroundMessage has a registered handler at all,
  // a requirement for background delivery on Android.
}

/// Attempts real Firebase setup once, at app start. Never throws: with
/// placeholder or missing platform config (no `flutterfire configure` run
/// yet), this fails and push notifications simply stay unavailable — every
/// other feature in the app is unaffected either way.
Future<bool> initializeFirebase() async {
  try {
    final options = DefaultFirebaseOptions.currentPlatform;
    // The native Firebase SDKs validate field formats (e.g. appId) and throw
    // a native exception synchronously on malformed input — on iOS this
    // crashes the whole process with SIGABRT before it ever reaches this
    // try/catch, since it isn't a normal Dart error crossing the platform
    // channel. So the placeholder must never even be handed to
    // Firebase.initializeApp(); this check has to happen first.
    if (options.apiKey == DefaultFirebaseOptions.placeholderMarker) {
      debugPrint(
        'Firebase not configured yet (run `flutterfire configure` to enable '
        'push notifications) — continuing without it.',
      );
      return false;
    }
    await Firebase.initializeApp(options: options);
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    return true;
  } catch (error) {
    debugPrint(
      'Firebase not configured yet (run `flutterfire configure` to enable '
      'push notifications) — continuing without it. ($error)',
    );
    return false;
  }
}
