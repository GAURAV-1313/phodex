import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/shared/theme/theme.dart';

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
    final items = <(StitchTab, IconData, String, String)>[
      (StitchTab.home, Icons.smart_toy_outlined, 'Agents', '/home'),
      (StitchTab.activity, Icons.assignment_outlined, 'Tasks', '/activity'),
      (StitchTab.repos, Icons.folder_outlined, 'Repos', '/repos'),
      (StitchTab.account, Icons.person_outline, 'Account', '/account'),
    ];
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.86),
        borderRadius: BorderRadius.circular(36),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 26,
            offset: Offset(0, 10),
          ),
        ],
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
    );
  }
}

class StitchHeader extends StatelessWidget {
  const StitchHeader({
    super.key,
    required this.title,
    this.onBell,
    this.onBack,
  });
  final String title;
  final VoidCallback? onBell;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
    child: Row(
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
          const CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.bgInput,
            child: Icon(
              Icons.smart_toy_outlined,
              color: AppColors.accentPrimary,
            ),
          ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              letterSpacing: -.8,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        IconButton(
          onPressed: onBell,
          icon: Badge(
            isLabelVisible: onBell != null,
            smallSize: 7,
            child: const Icon(Icons.notifications_none_rounded, size: 29),
          ),
        ),
      ],
    ),
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
