import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/welcome/application/auth_controller.dart';
import 'package:mobile/shared/theme/theme.dart';
import 'package:mobile/shared/widgets/phodex_mascot.dart';
import 'package:mobile/shared/widgets/stitch_ui.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    ref.listen(authControllerProvider, (_, next) {
      if (next is AsyncData<void>) context.go('/home');
    });
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
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
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Start coding tasks, monitor live execution and safely approve changes from anywhere.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(flex: 4),
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
                const Text(
                  "Couldn't sign in. Check your connection and try again.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.accentError),
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
