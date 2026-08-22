import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/notifications/application/push_notification_controller.dart';
import 'package:mobile/shared/theme/theme.dart';
import 'package:mobile/shared/widgets/stitch_ui.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(pushNotificationControllerProvider);

    return StitchScaffold(
      active: StitchTab.account,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, stitchDockClearance),
        children: [
          StitchHeader(title: 'Notifications', onBack: () => context.pop()),
          const SizedBox(height: 28),
          StitchCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _iconFor(status),
                  size: 40,
                  color: _colorFor(status, context),
                ),
                const SizedBox(height: 16),
                Text(
                  _titleFor(status),
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _bodyFor(status),
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    height: 1.5,
                  ),
                ),
                if (status == PushPermissionStatus.notDetermined) ...[
                  const SizedBox(height: 20),
                  StitchPrimaryButton(
                    label: 'Enable notifications',
                    onPressed: () => ref
                        .read(pushNotificationControllerProvider.notifier)
                        .requestPermission(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "You'll be notified when your agent needs an approval, and when "
            'a task finishes or fails — never for routine progress updates.',
            style: TextStyle(color: context.colors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(PushPermissionStatus status) => switch (status) {
    PushPermissionStatus.granted => Icons.notifications_active_rounded,
    PushPermissionStatus.denied => Icons.notifications_off_rounded,
    PushPermissionStatus.unavailable => Icons.info_outline_rounded,
    PushPermissionStatus.notDetermined => Icons.notifications_none_rounded,
  };

  Color _colorFor(PushPermissionStatus status, BuildContext context) =>
      switch (status) {
        PushPermissionStatus.granted => context.colors.accentSuccess,
        PushPermissionStatus.denied => context.colors.accentError,
        PushPermissionStatus.unavailable => context.colors.textMuted,
        PushPermissionStatus.notDetermined => context.colors.accentPrimary,
      };

  String _titleFor(PushPermissionStatus status) => switch (status) {
    PushPermissionStatus.granted => 'Notifications are on',
    PushPermissionStatus.denied => 'Notifications are off',
    PushPermissionStatus.unavailable => "Not set up on this build yet",
    PushPermissionStatus.notDetermined => 'Stay in the loop while you\'re away',
  };

  String _bodyFor(PushPermissionStatus status) => switch (status) {
    PushPermissionStatus.granted =>
      "You'll get a push the moment your agent needs a decision or finishes "
          'a task.',
    PushPermissionStatus.denied =>
      'Phodex is blocked from sending notifications. Turn it back on in '
          "your phone's Settings app → Phodex → Notifications.",
    PushPermissionStatus.unavailable =>
      "This build hasn't been connected to a push notification project yet "
          '— that\'s a one-time setup step for whoever built this app, not '
          'something you need to do.',
    PushPermissionStatus.notDetermined =>
      'Get a push the moment your agent needs your approval, or when a '
          'task finishes or fails.',
  };
}
