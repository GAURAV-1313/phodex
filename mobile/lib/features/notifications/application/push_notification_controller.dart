import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/app/router/app_router.dart';
import 'package:mobile/core/providers/repository_providers.dart';

enum PushPermissionStatus {
  /// Firebase never initialized on this build — no `flutterfire configure`
  /// has been run yet. Distinct from `denied` so the UI can explain that
  /// clearly instead of implying the user did something wrong.
  unavailable,
  notDetermined,
  granted,
  denied,
}

final pushNotificationControllerProvider =
    AsyncNotifierProvider<PushNotificationController, PushPermissionStatus>(
      PushNotificationController.new,
    );

/// Owns the push-permission state and, once granted, keeps the device's FCM
/// token registered with the backend. Async so the Notifications screen can
/// show a real loading state while the OS is consulted, and an error state
/// if Firebase itself misbehaves — instead of pretending to know the answer.
///
/// Built once at startup by `PushBootstrapper` (for signed-in users on a
/// Firebase-enabled build) so a previously granted permission re-registers
/// its token silently, and again by the Notifications screens on demand.
class PushNotificationController extends AsyncNotifier<PushPermissionStatus> {
  StreamSubscription<RemoteMessage>? _openedAppSub;
  StreamSubscription<String>? _tokenRefreshSub;

  @override
  Future<PushPermissionStatus> build() async {
    ref.onDispose(() {
      _openedAppSub?.cancel();
      _tokenRefreshSub?.cancel();
    });

    if (!ref.read(firebaseAvailableProvider)) {
      return PushPermissionStatus.unavailable;
    }

    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    final status = _mapStatus(settings.authorizationStatus);
    if (status == PushPermissionStatus.granted) await _activate();
    return status;
  }

  Future<void> requestPermission() async {
    if (!ref.read(firebaseAvailableProvider)) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final settings = await FirebaseMessaging.instance.requestPermission();
      final status = _mapStatus(settings.authorizationStatus);
      if (status == PushPermissionStatus.granted) await _activate();
      return status;
    });
  }

  /// Registers the current token and starts listening for refreshes and
  /// notification taps. Registration is best-effort: a backend hiccup here
  /// must not turn a granted permission into an error state.
  Future<void> _activate() async {
    try {
      await _registerCurrentToken();
    } catch (error) {
      debugPrint('Push token registration failed: $error');
    }
    _listenForTaps();
  }

  Future<void> _registerCurrentToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;
    await ref
        .read(pushRepositoryProvider)
        .registerToken(fcmToken: token, platform: _platformName);
  }

  void _listenForTaps() {
    _tokenRefreshSub ??= FirebaseMessaging.instance.onTokenRefresh.listen((
      token,
    ) {
      ref
          .read(pushRepositoryProvider)
          .registerToken(fcmToken: token, platform: _platformName)
          .catchError((Object error) {
            debugPrint('Push token re-registration failed: $error');
          });
    });
    _openedAppSub ??= FirebaseMessaging.onMessageOpenedApp.listen(
      _handleMessageTap,
    );
  }

  void _handleMessageTap(RemoteMessage message) {
    final taskId = message.data['task_id'];
    if (taskId is String && taskId.isNotEmpty) {
      ref.read(appRouterProvider).go('/session/$taskId');
    }
  }

  String get _platformName => Platform.isIOS ? 'ios' : 'android';

  PushPermissionStatus _mapStatus(AuthorizationStatus status) {
    return switch (status) {
      AuthorizationStatus.authorized ||
      AuthorizationStatus.provisional => PushPermissionStatus.granted,
      AuthorizationStatus.denied => PushPermissionStatus.denied,
      AuthorizationStatus.notDetermined => PushPermissionStatus.notDetermined,
    };
  }
}
