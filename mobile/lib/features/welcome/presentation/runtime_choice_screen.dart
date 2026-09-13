import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/welcome/application/runtime_choice_controller.dart';
import 'package:mobile/features/welcome/presentation/onboarding_nav.dart';
import 'package:mobile/shared/theme/theme.dart';
import 'package:mobile/shared/widgets/stitch_ui.dart';

/// "Where should tasks run?" — the one decision that shapes everything
/// after it (sign-in target, which repos are available). Reached from
/// Welcome during onboarding, and again from Account (`?from=account`) to
/// switch later, in which case a choice returns to Account instead of
/// pushing on to sign-in.
class RuntimeChoiceScreen extends ConsumerWidget {
  const RuntimeChoiceScreen({super.key, this.from});

  final String? from;

  bool get _fromAccount => from == OnboardingFrom.account;

  Future<void> _chooseCloud(BuildContext context, WidgetRef ref) async {
    final ok = await ref.read(runtimeChoiceProvider.notifier).chooseCloud();
    if (!ok || !context.mounted) return;
    if (_fromAccount) {
      context.pop(true);
    } else {
      context.push('/sign-in');
    }
  }

  Future<void> _chooseDesktop(BuildContext context, WidgetRef ref) async {
    ref.read(runtimeChoiceProvider.notifier).chooseDesktop();
    final target = _fromAccount
        ? '/connect-desktop?from=${OnboardingFrom.account}'
        : '/connect-desktop';
    final paired = await context.push<bool>(target);
    // Coming from Account, a successful pairing is the whole job — unwind
    // straight back rather than leaving this choice screen on the stack.
    if (paired == true && _fromAccount && context.mounted) context.pop(true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final choice = ref.watch(runtimeChoiceProvider);
    return StitchScaffold(
      key: const Key('runtime-choice-screen'),
      showDock: false,
      child: ListView(
        padding: stitchScreenPaddingNoDock,
        children: [
          StitchHeader(
            title: 'Choose a runtime',
            onBack: () =>
                popOrGo(context, _fromAccount ? '/account' : '/welcome'),
          ),
          const SizedBox(height: AppSpacing.s16),
          Text(
            'You can switch at any time from Account.',
            style: context.text.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.s24),
          if (choice.errorMessage != null) ...[
            StatusBanner(
              message: choice.errorMessage!,
              tone: StatusTone.error,
              actionLabel: 'Retry',
              onAction: choice.busy ? null : () => _chooseCloud(context, ref),
            ),
            const SizedBox(height: AppSpacing.s16),
          ],
          _RuntimeOptionCard(
            key: const Key('runtime-option-cloud'),
            icon: Icons.cloud_outlined,
            title: 'Phodex Cloud',
            badge: 'Recommended',
            body:
                'Runs on a hosted runner. Works with your laptop closed, '
                'and connects to any GitHub repo.',
            semanticsLabel:
                'Phodex Cloud, recommended. Runs on a hosted runner, works '
                'with your laptop closed, connects to any GitHub repo.',
            busy: choice.busy,
            onTap: choice.busy ? null : () => _chooseCloud(context, ref),
          ),
          const SizedBox(height: AppSpacing.s16),
          _RuntimeOptionCard(
            key: const Key('runtime-option-desktop'),
            icon: Icons.laptop_mac_outlined,
            title: 'My desktop',
            body:
                'Pair your laptop over Wi-Fi or Tailscale. Tasks run on your '
                'own machine, with your own tools.',
            semanticsLabel:
                'My desktop. Pair your laptop over Wi-Fi or Tailscale; tasks '
                'run on your own machine.',
            onTap: choice.busy ? null : () => _chooseDesktop(context, ref),
          ),
        ],
      ),
    );
  }
}

class _RuntimeOptionCard extends StatelessWidget {
  const _RuntimeOptionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.semanticsLabel,
    required this.onTap,
    this.badge,
    this.busy = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final String semanticsLabel;
  final String? badge;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: semanticsLabel,
      onTap: onTap,
      child: ExcludeSemantics(
        child: StitchCard(
          onTap: onTap,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: AppSpacing.s48,
                height: AppSpacing.s48,
                decoration: BoxDecoration(
                  color: colors.accentPrimarySoft,
                  borderRadius: BorderRadius.circular(AppRadii.chip),
                ),
                child: Icon(icon, color: colors.accentPrimaryDeep),
              ),
              const SizedBox(width: AppSpacing.s16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (badge != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s8,
                          vertical: AppSpacing.s2,
                        ),
                        decoration: BoxDecoration(
                          color: colors.accentPrimarySoft,
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                        ),
                        child: Text(
                          badge!.toUpperCase(),
                          style: context.text.labelSmall?.copyWith(
                            color: colors.accentPrimaryDeep,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s8),
                    ],
                    Text(title, style: context.text.titleLarge),
                    const SizedBox(height: AppSpacing.s4),
                    Text(body, style: context.text.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              if (busy)
                const SizedBox(
                  width: AppSpacing.s20,
                  height: AppSpacing.s20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(Icons.chevron_right_rounded, color: colors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
