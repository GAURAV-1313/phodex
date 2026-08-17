import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/shared/theme/theme.dart';
import 'package:mobile/shared/widgets/phodex_mascot.dart';

/// Height reserved for the floating dock + its clear-space gradient. Screens
/// with a [StitchScaffold] should use at least this much bottom padding on
/// their scrollable content so nothing sits hidden behind the dock at rest.
const double stitchDockClearance = 128;

/// Standard loading state — the mascot mid-thought instead of a generic
/// platform spinner, used everywhere the app is waiting on the backend.
class PhodexLoading extends StatelessWidget {
  const PhodexLoading({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: PhodexMascot(size: 64, mood: MascotMood.thinking));
}

class StitchScaffold extends StatelessWidget {
  const StitchScaffold({
    super.key,
    required this.child,
    this.active = StitchTab.home,
  });

  final Widget child;
  final StitchTab active;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: child),
            // Fades scrolled content out before it reaches the dock, so
            // anything passing underneath never looks abruptly clipped.
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 116,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x00FBF9F7),
                        AppColors.bgPrimary,
                      ],
                      stops: [0.0, 0.62],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 16,
              child: StitchDock(active: active),
            ),
          ],
        ),
      ),
    );
  }
}

enum StitchTab { home, activity, repos, account }

class StitchDock extends StatelessWidget {
  const StitchDock({super.key, required this.active});
  final StitchTab active;

  @override
  Widget build(BuildContext context) {
    final items = <(StitchTab, IconData?, String, String)>[
      (StitchTab.home, null, 'Agents', '/home'),
      (StitchTab.activity, Icons.assignment_outlined, 'Tasks', '/activity'),
      (StitchTab.repos, Icons.folder_outlined, 'Repos', '/repos'),
      (StitchTab.account, Icons.person_outline, 'Account', '/account'),
    ];
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(36)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 26,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .78),
              border: Border.all(color: Colors.white.withValues(alpha: .6)),
              borderRadius: BorderRadius.circular(36),
            ),
            child: Row(
              children: [
                for (final item in items)
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(28),
                      onTap: () => context.go(item.$4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (item.$2 == null)
                            PhodexMascotGlyph(
                              size: 24,
                              color: active == item.$1
                                  ? AppColors.accentPrimary
                                  : AppColors.textSecondary,
                            )
                          else
                            Icon(
                              item.$2,
                              color: active == item.$1
                                  ? AppColors.accentPrimary
                                  : AppColors.textSecondary,
                            ),
                          const SizedBox(height: 3),
                          Text(
                            item.$3,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: active == item.$1
                                  ? AppColors.accentPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A screen's top row. On top-level tab screens (no [onBack], no [title])
/// the mascot itself is the brand mark — no "Phodex" wordmark repeated on
/// every screen. Detail screens pass [title] and [onBack] for real
/// navigational context instead.
class StitchHeader extends StatelessWidget {
  const StitchHeader({super.key, this.title, this.onBell, this.onBack});
  final String? title;
  final VoidCallback? onBell;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      if (onBack != null)
        IconButton(
          onPressed: onBack,
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.accentPrimary,
          ),
        )
      else
        const PhodexMascot(size: 40),
      const SizedBox(width: 12),
      if (title != null)
        Expanded(
          child: Text(
            title!,
            style: AppTypography.display(
              fontSize: AppTypeScale.headline,
              letterSpacing: -.8,
            ),
          ),
        )
      else
        const Spacer(),
      IconButton(
        onPressed: onBell,
        icon: Badge(
          isLabelVisible: onBell != null,
          smallSize: 7,
          child: const Icon(Icons.notifications_none_rounded, size: 29),
        ),
      ),
    ],
  );
}

class StitchCard extends StatelessWidget {
  const StitchCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
  });
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
    child: InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 24,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: child,
      ),
    ),
  );
}

class StitchPrimaryButton extends StatelessWidget {
  const StitchPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 58,
    width: double.infinity,
    child: FilledButton.icon(
      onPressed: onPressed,
      icon: icon == null ? const SizedBox.shrink() : Icon(icon),
      label: Text(
        label,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accentPrimary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
  );
}

Color taskStatusColor(String value) => switch (value) {
  'completed' => AppColors.accentSuccess,
  'waiting_approval' => AppColors.accentWarning,
  'failed' => AppColors.accentError,
  _ => AppColors.accentPrimary,
};

/// Friendly error state for async views — never surfaces the raw exception
/// text (stack traces, HTTP client internals) to the user.
class StitchErrorState extends StatelessWidget {
  const StitchErrorState({
    super.key,
    this.title = "Something didn't load",
    this.message = 'Check your connection and try again.',
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PhodexMascot(size: 72, mood: MascotMood.error),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try again'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accentPrimary,
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
