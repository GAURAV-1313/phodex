import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/account/application/account_controller.dart';
import 'package:mobile/features/welcome/application/auth_controller.dart';
import 'package:mobile/shared/theme/theme.dart';
import 'package:mobile/shared/widgets/stitch_ui.dart';

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
            final runtimeLive = dashboard.summary.activeSessions > 0;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
              children: [
                const StitchHeader(title: 'Phodex'),
                const SizedBox(height: 54),
                const CircleAvatar(
                  radius: 52,
                  backgroundColor: AppColors.bgInput,
                  child: Icon(
                    Icons.person_outline,
                    size: 52,
                    color: AppColors.textSecondary,
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
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
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
                        style: const TextStyle(
                          fontSize: 40,
                          letterSpacing: -1,
                          color: AppColors.accentPrimary,
                        ),
                      ),
                      const Text(
                        'Automated tasks',
                        style: TextStyle(fontSize: 17),
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
                                  ? AppColors.accentSuccess
                                  : AppColors.textMuted,
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
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Row(
                        children: [
                          Icon(
                            Icons.terminal_rounded,
                            color: AppColors.accentPrimary,
                          ),
                          SizedBox(width: 9),
                          Text(
                            'Host-run worker',
                            style: TextStyle(
                              color: AppColors.accentPrimary,
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
                  child: const Column(
                    children: [
                      _Setting(
                        icon: Icons.notifications_none_rounded,
                        label: 'Notifications',
                      ),
                      Divider(height: 1),
                      _Setting(
                        icon: Icons.palette_outlined,
                        label: 'Appearance',
                      ),
                      Divider(height: 1),
                      _Setting(
                        icon: Icons.lock_outline,
                        label: 'Privacy & security',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                StitchCard(
                  padding: EdgeInsets.zero,
                  child: const _Setting(
                    icon: Icons.help_outline,
                    label: 'Support center',
                  ),
                ),
                const SizedBox(height: 34),
                Center(
                  child: TextButton(
                    onPressed: () async {
                      await ref.read(authControllerProvider.notifier).signOut();
                      if (context.mounted) context.go('/welcome');
                    },
                    child: const Text(
                      'Sign out',
                      style: TextStyle(
                        color: AppColors.accentError,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Center(
                  child: Text(
                    'Phodex local build',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              Center(child: Text('Could not load account: $error')),
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
    style: const TextStyle(letterSpacing: 1.5, color: AppColors.textSecondary),
  );
}

class _Setting extends StatelessWidget {
  const _Setting({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.bgInput,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon),
        ),
        const SizedBox(width: 16),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 17))),
        const Icon(Icons.chevron_right, color: AppColors.textMuted),
      ],
    ),
  );
}
