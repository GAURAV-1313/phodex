import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
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
    NotifierProvider<PushNotificationController, PushPermissionStatus>(
      PushNotificationController.new,
    );

class PushNotificationController extends Notifier<PushPermissionStatus> {
  StreamSubscription<RemoteMessage>? _openedAppSub;
  StreamSubscription<String>? _tokenRefreshSub;

  @override
  PushPermissionStatus build() {
    ref.onDispose(() {
      _openedAppSub?.cancel();
      _tokenRefreshSub?.cancel();
    });

    if (!ref.read(firebaseAvailableProvider)) {
      return PushPermissionStatus.unavailable;
    }

    unawaited(_refreshStatus());
    return PushPermissionStatus.notDetermined;
  }

  Future<void> _refreshStatus() async {
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    state = _mapStatus(settings.authorizationStatus);
    if (state == PushPermissionStatus.granted) {
      await _registerCurrentToken();
      _listenForTaps();
    }
  }

  Future<void> requestPermission() async {
    if (!ref.read(firebaseAvailableProvider)) return;
    final settings = await FirebaseMessaging.instance.requestPermission();
    state = _mapStatus(settings.authorizationStatus);
    if (state == PushPermissionStatus.granted) {
      await _registerCurrentToken();
      _listenForTaps();
    }
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
          .registerToken(fcmToken: token, platform: _platformName);
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
