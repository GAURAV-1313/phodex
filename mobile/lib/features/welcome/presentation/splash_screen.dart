import 'package:flutter/material.dart';
import 'package:mobile/shared/theme/theme.dart';
import 'package:mobile/shared/widgets/phodex_mascot.dart';

/// Shown only while the app is still working out where to send the user
/// (session restore, onboarding flags) — the router replaces it the moment
/// that's known, so it never needs any chrome of its own.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    key: const Key('splash-screen'),
    backgroundColor: context.colors.bgPrimary,
    body: Center(
      child: Semantics(
        label: 'Starting Phodex',
        liveRegion: true,
        child: const PhodexMascot(size: 96, mood: MascotMood.thinking),
      ),
    ),
  );
}
