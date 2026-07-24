import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/welcome/application/auth_controller.dart';
import 'package:mobile/shared/theme/theme.dart';
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
              Container(
                width: 116,
                height: 116,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(color: Color(0x10000000), blurRadius: 24),
                  ],
                ),
                child: const Icon(
                  Icons.camera_outlined,
                  size: 70,
                  color: AppColors.accentPrimary,
                ),
              ),
              const SizedBox(height: 78),
              const Text(
                'Your AI engineer,\nin your pocket.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 35,
                  height: 1.08,
                  letterSpacing: -1.3,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Start coding tasks, monitor live execution and safely approve changes from anywhere.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(flex: 4),
              StitchPrimaryButton(
                label: authState.isLoading
                    ? 'Connecting…'
                    : 'Continue with Google',
                icon: Icons.g_mobiledata_rounded,
                onPressed: authState.isLoading
                    ? null
                    : () => ref.read(authControllerProvider.notifier).signIn(),
              ),
              if (authState.hasError) ...[
                const SizedBox(height: 14),
                Text(
                  'Could not sign in. ${authState.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.accentError),
                ),
              ],
              const SizedBox(height: 24),
              const Text(
                'Terms  •  Privacy',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
