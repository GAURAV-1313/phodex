import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/notifications/application/push_notification_controller.dart';
import 'package:mobile/shared/theme/theme.dart';
import 'package:mobile/shared/widgets/phodex_mascot.dart';
import 'package:mobile/shared/widgets/stitch_ui.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(pushNotificationControllerProvider);

    return StitchScaffold(
      key: const Key('notifications-screen'),
      active: StitchTab.account,
      child: ListView(
        padding: stitchScreenPadding,
        children: [
          StitchHeader(title: 'Notifications', onBack: () => context.pop()),
          const SizedBox(height: AppSpacing.s24),
          StitchAsyncView<PushPermissionStatus>(
            value: status,
            loadingMessage: 'Checking notification settings…',
            errorTitle: "Couldn't check notification settings",
            onRetry: () => ref.invalidate(pushNotificationControllerProvider),
            builder: (context, permission) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StitchCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: PhodexMascot(
                          size: 72,
                          mood: _moodFor(permission),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s16),
                      Text(
                        _titleFor(permission),
                        style: context.text.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.s8),
                      Text(
                        _bodyFor(permission),
                        style: context.text.bodyMedium,
                      ),
                      if (permission == PushPermissionStatus.notDetermined) ...[
                        const SizedBox(height: AppSpacing.s20),
                        StitchPrimaryButton(
                          label: 'Enable notifications',
                          icon: Icons.notifications_active_outlined,
                          onPressed: () => ref
                              .read(pushNotificationControllerProvider.notifier)
                              .requestPermission(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s20),
                Text(
                  "You'll be notified when your agent needs an approval, and "
                  'when a task finishes or fails — never for routine '
                  'progress updates.',
                  style: context.text.bodySmall?.copyWith(
                    color: context.colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  MascotMood _moodFor(PushPermissionStatus status) => switch (status) {
    PushPermissionStatus.granted => MascotMood.success,
    PushPermissionStatus.denied => MascotMood.error,
    PushPermissionStatus.unavailable => MascotMood.resting,
    PushPermissionStatus.notDetermined => MascotMood.curious,
  };

  String _titleFor(PushPermissionStatus status) => switch (status) {
    PushPermissionStatus.granted => 'Notifications are on',
    PushPermissionStatus.denied => 'Notifications are off',
    PushPermissionStatus.unavailable => 'Not set up on this build yet',
    PushPermissionStatus.notDetermined => "Stay in the loop while you're away",
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
          "— that's a one-time setup step for whoever built this app, not "
          'something you need to do.',
    PushPermissionStatus.notDetermined =>
      'Get a push the moment your agent needs your approval, or when a '
          'task finishes or fails.',
  };
}
