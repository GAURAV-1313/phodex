import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/core/network/server_connection_controller.dart';
import 'package:mobile/core/providers/repository_providers.dart';
import 'package:mobile/features/welcome/application/auth_controller.dart';
import 'package:mobile/features/welcome/application/runtime_choice_controller.dart';
import 'package:mobile/features/welcome/presentation/onboarding_nav.dart';
import 'package:mobile/shared/theme/theme.dart';
import 'package:mobile/shared/widgets/phodex_mascot.dart';
import 'package:mobile/shared/widgets/stitch_ui.dart';

/// Sign in against whichever runtime the user just chose. A successful
/// sign-in doesn't navigate from here: the router's guard notices the auth
/// state change and sends the user to the next onboarding step (or Home).
class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final choice = ref.watch(runtimeChoiceProvider);
    final serverUrl = ref.watch(serverUrlProvider);
    final config = ref.watch(apiConfigProvider);
    final mockRuntimeMode = config.useNetwork
        ? null
        : ref.watch(mockBackendStoreProvider).runtimeMode;

    final configured = serverUrl != null && serverUrl.isNotEmpty;
    final isCloud =
        choice.mode == RuntimeMode.cloud ||
        (configured && serverUrl == config.cloudBaseUrl);
    final hasRuntime = choice.mode != null || configured;
    final demoAvailable =
        choice.demoAvailable || mockRuntimeMode == RuntimeMode.cloud;
    final needsRuntime = config.useNetwork && !configured;
    final busy = auth.isLoading;
    final failure = busy ? null : auth.failure;

    return StitchScaffold(
      key: const Key('sign-in-screen'),
      showDock: false,
      child: ListView(
        padding: stitchScreenPaddingNoDock,
        children: [
          StitchHeader(
            title: 'Sign in',
            onBack: () => popOrGo(context, '/runtime'),
          ),
          const SizedBox(height: AppSpacing.s24),
          Center(
            child: PhodexMascot(
              size: 80,
              mood: failure != null
                  ? MascotMood.error
                  : busy
                  ? MascotMood.thinking
                  : MascotMood.idle,
            ),
          ),
          const SizedBox(height: AppSpacing.s24),
          _RuntimeSummary(
            hasRuntime: hasRuntime,
            isCloud: isCloud,
            url: serverUrl,
            onChange: () => context.push('/runtime'),
          ),
          const SizedBox(height: AppSpacing.s24),
          if (needsRuntime) ...[
            StatusBanner(
              message: 'Choose where tasks run first',
              tone: StatusTone.warning,
              actionLabel: 'Choose',
              onAction: () => context.push('/runtime'),
            ),
            const SizedBox(height: AppSpacing.s16),
          ],
          if (failure != null) ...[
            StatusBanner(
              key: const Key('sign-in-error'),
              message: _messageFor(failure),
              tone: StatusTone.error,
              actionLabel: failure == AuthFailure.runtimeUnreachable
                  ? 'Change runtime'
                  : null,
              onAction: failure == AuthFailure.runtimeUnreachable
                  ? () => context.push('/runtime')
                  : null,
            ),
            const SizedBox(height: AppSpacing.s16),
          ],
          Semantics(
            button: true,
            label: 'Continue with Google',
            child: StitchPrimaryButton(
              key: const Key('sign-in-google'),
              label: 'Continue with Google',
              icon: Icons.login_rounded,
              loading: busy,
              onPressed: needsRuntime
                  ? null
                  : () => ref.read(authControllerProvider.notifier).signIn(),
            ),
          ),
          if (demoAvailable) ...[
            const SizedBox(height: AppSpacing.s12),
            Semantics(
              button: true,
              label: 'Try the demo account without signing in',
              child: StitchSecondaryButton(
                key: const Key('sign-in-demo'),
                label: 'Try the demo',
                icon: Icons.explore_outlined,
                onPressed: busy
                    ? null
                    : () => ref
                          .read(authControllerProvider.notifier)
                          .signInAsDemo(),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.s24),
          Text(
            'Your Google account only identifies you. Phodex never sees '
            'your password.',
            textAlign: TextAlign.center,
            style: context.text.bodySmall?.copyWith(
              color: context.colors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  static String _messageFor(AuthFailure failure) => switch (failure) {
    AuthFailure.cancelled => 'Sign-in was cancelled.',
    AuthFailure.noNetwork =>
      'No internet connection. Check your network, then try again.',
    AuthFailure.unsupportedPlatform =>
      "Google sign-in isn't available on this platform yet.",
    AuthFailure.runtimeUnreachable =>
      "Couldn't reach your runtime. Check that it's online, then try again.",
    AuthFailure.unknown => "Couldn't sign in. Please try again.",
  };
}

/// Where sign-in will happen, so the user can confirm the earlier choice
/// stuck — and switch without backing out through the whole flow.
class _RuntimeSummary extends StatelessWidget {
  const _RuntimeSummary({
    required this.hasRuntime,
    required this.isCloud,
    required this.url,
    required this.onChange,
  });

  final bool hasRuntime;
  final bool isCloud;
  final String? url;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (icon, title, subtitle) = !hasRuntime
        ? (Icons.help_outline_rounded, 'No runtime chosen', 'Pick one below')
        : isCloud
        ? (Icons.cloud_outlined, 'Phodex Cloud', 'Hosted runner')
        : (
            Icons.laptop_mac_outlined,
            'Desktop',
            url ?? 'Pair your laptop to continue',
          );
    return StitchCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s16,
        AppSpacing.s12,
        AppSpacing.s8,
        AppSpacing.s12,
      ),
      child: Row(
        children: [
          Container(
            width: AppSpacing.s40,
            height: AppSpacing.s40,
            decoration: BoxDecoration(
              color: colors.accentPrimarySoft,
              borderRadius: BorderRadius.circular(AppRadii.chip),
            ),
            child: Icon(icon, size: 20, color: colors.accentPrimaryDeep),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.titleMedium),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
          TextButton(
            key: const Key('sign-in-change-runtime'),
            onPressed: onChange,
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }
}
