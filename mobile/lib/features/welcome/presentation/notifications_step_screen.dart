import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/providers/repository_providers.dart';
import 'package:mobile/features/notifications/application/push_notification_controller.dart';
import 'package:mobile/features/welcome/application/onboarding_controller.dart';
import 'package:mobile/shared/theme/theme.dart';
import 'package:mobile/shared/widgets/phodex_mascot.dart';
import 'package:mobile/shared/widgets/stitch_ui.dart';

/// The last onboarding step: ask for push permission with a reason, at the
/// one moment the user knows what they'd be notified about. Either answer
/// completes onboarding — declining here just means Home, not a nag loop.
class NotificationsStepScreen extends ConsumerStatefulWidget {
  const NotificationsStepScreen({super.key});

  @override
  ConsumerState<NotificationsStepScreen> createState() =>
      _NotificationsStepScreenState();
}

class _NotificationsStepScreenState
    extends ConsumerState<NotificationsStepScreen> {
  bool _busy = false;

  Future<void> _enable() async {
    setState(() => _busy = true);
    if (ref.read(firebaseAvailableProvider)) {
      try {
        await ref
            .read(pushNotificationControllerProvider.notifier)
            .requestPermission();
      } catch (_) {
        // A permission prompt that fails to show is not a reason to stall
        // onboarding; the Notifications screen can retry later.
      }
    }
    await _finish();
  }

  Future<void> _finish() async {
    final onboarding = ref.read(onboardingControllerProvider.notifier);
    await onboarding.markNotificationsPrompted();
    await onboarding.complete();
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return StitchScaffold(
      key: const Key('notifications-step-screen'),
      showDock: false,
      child: CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: stitchScreenPaddingNoDock,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 2),
                  const Center(
                    child: PhodexMascot(size: 96, mood: MascotMood.curious),
                  ),
                  const SizedBox(height: AppSpacing.s32),
                  Semantics(
                    header: true,
                    child: Text(
                      "Know when you're needed",
                      textAlign: TextAlign.center,
                      style: context.text.headlineLarge,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  Text(
                    'Your agent works while your phone is in your pocket. '
                    "We'll send a push when it needs your approval, and "
                    'when a task finishes or fails — never for routine '
                    'progress.',
                    textAlign: TextAlign.center,
                    style: context.text.bodyLarge?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const Spacer(flex: 3),
                  StitchPrimaryButton(
                    key: const Key('notifications-step-enable'),
                    label: 'Enable notifications',
                    icon: Icons.notifications_active_outlined,
                    loading: _busy,
                    onPressed: _enable,
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  StitchSecondaryButton(
                    key: const Key('notifications-step-skip'),
                    label: 'Not now',
                    onPressed: _busy ? null : _finish,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
