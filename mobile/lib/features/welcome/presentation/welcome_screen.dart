import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/shared/theme/theme.dart';
import 'package:mobile/shared/widgets/phodex_mascot.dart';
import 'package:mobile/shared/widgets/stitch_ui.dart';

/// The first screen a signed-out user sees. Pure pitch: what Phodex does
/// and one way forward. Where tasks run and how to sign in are separate,
/// later steps — nothing here talks to a backend, so there is nothing to
/// be "connecting" to yet.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      key: const Key('welcome-screen'),
      backgroundColor: colors.bgPrimary,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s32,
                  AppSpacing.s24,
                  AppSpacing.s32,
                  AppSpacing.s24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(flex: 2),
                    const Center(
                      child: PhodexMascot(size: 108, mood: MascotMood.idle),
                    ),
                    const SizedBox(height: AppSpacing.s40),
                    Semantics(
                      header: true,
                      child: Text(
                        'Your AI engineer,\nin your pocket.',
                        textAlign: TextAlign.center,
                        style: context.text.displayLarge,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    Text(
                      'Ship code from anywhere — your agent does the typing.',
                      textAlign: TextAlign.center,
                      style: context.text.bodyLarge?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s40),
                    const _ValueBullet(
                      icon: Icons.rocket_launch_outlined,
                      text: 'Start tasks from your phone',
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    const _ValueBullet(
                      icon: Icons.visibility_outlined,
                      text: 'Watch live execution as it happens',
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    const _ValueBullet(
                      icon: Icons.verified_user_outlined,
                      text: 'Approve every change before it lands',
                    ),
                    const Spacer(flex: 3),
                    StitchPrimaryButton(
                      key: const Key('welcome-get-started'),
                      label: 'Get started',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: () => context.push('/runtime'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValueBullet extends StatelessWidget {
  const _ValueBullet({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
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
        const SizedBox(width: AppSpacing.s16),
        Expanded(child: Text(text, style: context.text.bodyLarge)),
      ],
    );
  }
}
