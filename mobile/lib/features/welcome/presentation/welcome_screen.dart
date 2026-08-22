import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/network/server_connection_controller.dart';
import 'package:mobile/features/welcome/application/auth_controller.dart';
import 'package:mobile/shared/theme/theme.dart';
import 'package:mobile/shared/widgets/phodex_mascot.dart';
import 'package:mobile/shared/widgets/stitch_ui.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final serverUrl = ref.watch(serverUrlProvider);
    ref.listen(authControllerProvider, (_, next) {
      if (next.value == true) context.go('/home');
    });
    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: Column(
            children: [
              const Spacer(flex: 3),
              const PhodexMascot(size: 108),
              const SizedBox(height: 52),
              Text(
                'Your AI engineer,\nin your pocket.',
                textAlign: TextAlign.center,
                style: AppTypography.display(
                  fontSize: 38,
                  height: 1.08,
                  letterSpacing: -0.5,
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Start coding tasks, monitor live execution and safely approve changes from anywhere.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  height: 1.5,
                  color: context.colors.textSecondary,
                ),
              ),
              const Spacer(flex: 4),
              InkWell(
                onTap: () => context.push('/connect-desktop'),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.desktop_windows_outlined,
                        size: 16,
                        color: serverUrl == null
                            ? context.colors.accentWarning
                            : context.colors.accentSuccess,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          serverUrl == null
                              ? 'Connect to your desktop first'
                              : 'Connected to $serverUrl · Change',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: context.colors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              StitchPrimaryButton(
                label: authState.isLoading
                    ? 'Connecting…'
                    : 'Continue with Google',
                onPressed: authState.isLoading
                    ? null
                    : () => ref.read(authControllerProvider.notifier).signIn(),
              ),
              if (authState.hasError) ...[
                const SizedBox(height: 14),
                Text(
                  "Couldn't sign in. Check your connection and try again.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.colors.accentError),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
