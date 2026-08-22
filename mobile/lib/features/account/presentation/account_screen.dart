import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/account/application/account_controller.dart';
import 'package:mobile/features/welcome/application/auth_controller.dart';
import 'package:mobile/shared/theme/theme.dart';
import 'package:mobile/shared/widgets/stitch_ui.dart';
import 'package:url_launcher/url_launcher.dart';

const _supportUrl = 'https://github.com/GAURAV-1313/phodex/issues/new';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(accountDashboardProvider);
    return StitchScaffold(
      active: StitchTab.account,
      child: RefreshIndicator(
        onRefresh: () => ref.read(accountDashboardProvider.notifier).refresh(),
        child: value.when(
          data: (dashboard) {
            final user = dashboard.summary.user;
            final runtimeLive = dashboard.summary.deviceOnline;
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                24,
                16,
                24,
                stitchDockClearance,
              ),
              children: [
                StitchHeader(onBell: () => context.push('/approvals')),
                const SizedBox(height: 44),
                Text(
                  'Account',
                  style: AppTypography.display(
                    fontSize: AppTypeScale.displayLarge,
                    letterSpacing: -1,
                    color: context.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 28),
                CircleAvatar(
                  radius: 52,
                  backgroundColor: context.colors.bgInput,
                  child: Icon(
                    Icons.person_outline,
                    size: 52,
                    color: context.colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  user.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  user.email,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: context.colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 42),
                StitchCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionLabel('Usage this month'),
                      const SizedBox(height: 14),
                      Text(
                        '${dashboard.usage.totalTasks}',
                        style: AppTypography.display(
                          fontSize: AppTypeScale.displayLarge,
                          letterSpacing: -1,
                          color: context.colors.accentPrimary,
                        ),
                      ),
                      const Text(
                        'Automated tasks',
                        style: TextStyle(fontSize: AppTypeScale.body),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 22),
                        child: Divider(),
                      ),
                      const _SectionLabel('Current plan'),
                      const SizedBox(height: 10),
                      Text(
                        dashboard.limits.maxConcurrentTasks == null
                            ? 'Personal workspace'
                            : 'Managed workspace',
                        style: const TextStyle(fontSize: 17),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                StitchCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: _SectionLabel('Desktop runtime'),
                          ),
                          Chip(
                            label: Text(runtimeLive ? 'LIVE' : 'IDLE'),
                            avatar: Icon(
                              Icons.circle,
                              size: 10,
                              color: runtimeLive
                                  ? context.colors.accentSuccess
                                  : context.colors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Local Codex runtime',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        runtimeLive
                            ? 'Connected and ready for tasks'
                            : 'No active agent session',
                        style: TextStyle(
                          fontSize: 16,
                          color: context.colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Icon(
                            Icons.terminal_rounded,
                            color: context.colors.accentPrimary,
                          ),
                          const SizedBox(width: 9),
                          Text(
                            'Host-run worker',
                            style: TextStyle(
                              color: context.colors.accentPrimary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const _SectionLabel('System settings'),
                const SizedBox(height: 12),
                StitchCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _Setting(
                        icon: Icons.smart_toy_outlined,
                        label: 'AI engine',
                        onTap: () => context.push('/account/ai-engine'),
                      ),
                      const Divider(height: 1),
                      _Setting(
                        icon: Icons.desktop_windows_outlined,
                        label: 'Desktop connection',
                        onTap: () => context.push('/connect-desktop'),
                      ),
                      const Divider(height: 1),
                      _Setting(
                        icon: Icons.notifications_none_rounded,
                        label: 'Notifications',
                        onTap: () => context.push('/account/notifications'),
                      ),
                      const Divider(height: 1),
                      _Setting(
                        icon: Icons.palette_outlined,
                        label: 'Appearance',
                        onTap: () => _showAppearancePicker(context, ref),
                      ),
                      const Divider(height: 1),
                      _Setting(
                        icon: Icons.lock_outline,
                        label: 'Privacy & security',
                        onTap: () => context.push('/account/sessions'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                StitchCard(
                  padding: EdgeInsets.zero,
                  child: _Setting(
                    icon: Icons.help_outline,
                    label: 'Support center',
                    onTap: () => _openSupportCenter(context),
                  ),
                ),
                const SizedBox(height: 34),
                Center(
                  child: TextButton(
                    onPressed: () async {
                      await ref.read(authControllerProvider.notifier).signOut();
                      if (context.mounted) context.go('/welcome');
                    },
                    child: Text(
                      'Sign out',
                      style: TextStyle(
                        color: context.colors.accentError,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    'Phodex local build',
                    style: TextStyle(color: context.colors.textMuted),
                  ),
                ),
              ],
            );
          },
          loading: () => const PhodexLoading(),
          error: (error, _) => StitchErrorState(
            title: "Couldn't load your account",
            onRetry: () =>
                ref.read(accountDashboardProvider.notifier).refresh(),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label.toUpperCase(),
    style: TextStyle(letterSpacing: 1.5, color: context.colors.textSecondary),
  );
}

class _Setting extends StatelessWidget {
  const _Setting({required this.icon, required this.label, this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.colors.bgInput,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 17))),
          Icon(Icons.chevron_right, color: context.colors.textMuted),
        ],
      ),
    ),
  );
}

Future<void> _openSupportCenter(BuildContext context) async {
  final uri = Uri.parse(_supportUrl);
  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open the support page')),
    );
  }
}

void _showAppearancePicker(BuildContext context, WidgetRef ref) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Consumer(
      builder: (sheetContext, ref, _) {
        final current = ref.watch(themeModeProvider);
        return Container(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
          decoration: BoxDecoration(
            color: sheetContext.colors.bgSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: sheetContext.colors.borderSubtle,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Appearance',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 18),
              for (final option in const [
                (ThemeMode.system, 'System', Icons.brightness_auto_outlined),
                (ThemeMode.light, 'Light', Icons.light_mode_outlined),
                (ThemeMode.dark, 'Dark', Icons.dark_mode_outlined),
              ])
                _AppearanceOption(
                  mode: option.$1,
                  label: option.$2,
                  icon: option.$3,
                  selected: current == option.$1,
                  onTap: () {
                    ref
                        .read(themeModeProvider.notifier)
                        .setThemeMode(option.$1);
                    Navigator.pop(sheetContext);
                  },
                ),
            ],
          ),
        );
      },
    ),
  );
}

class _AppearanceOption extends StatelessWidget {
  const _AppearanceOption({
    required this.mode,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final ThemeMode mode;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: selected
                ? context.colors.accentPrimary
                : context.colors.textSecondary,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          if (selected)
            Icon(Icons.check_rounded, color: context.colors.accentPrimary),
        ],
      ),
    ),
  );
}
