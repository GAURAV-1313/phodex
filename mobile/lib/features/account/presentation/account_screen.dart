import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/account/application/account_controller.dart';
import 'package:mobile/shared/widgets/template_kit.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardValue = ref.watch(accountDashboardProvider);

    return TemplateScaffold(
      key: const Key('account-screen'),
      backgroundColor: TemplateColors.groupedBackground,
      bottomSafeArea: true,
      child: RefreshIndicator(
        onRefresh: () => ref.read(accountDashboardProvider.notifier).refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(17, 0, 17, 24),
            child: dashboardValue.when(
              data: (dashboard) => _AccountContent(
                dashboard: dashboard,
                onClose: () => context.go('/home'),
                onRepos: () => context.go('/repos'),
                onRecents: () => context.go('/home/recents'),
                onApprovals: () => context.go('/approvals'),
              ),
              loading: () => const Column(
                children: [
                  TemplateStatusBar(),
                  SizedBox(height: 220),
                  CircularProgressIndicator(),
                ],
              ),
              error: (error, _) => _AccountError(
                message: 'Could not load account: $error',
                onRetry: () =>
                    ref.read(accountDashboardProvider.notifier).refresh(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountContent extends StatelessWidget {
  const _AccountContent({
    required this.dashboard,
    required this.onClose,
    required this.onRepos,
    required this.onRecents,
    required this.onApprovals,
  });

  final AccountDashboard dashboard;
  final VoidCallback onClose;
  final VoidCallback onRepos;
  final VoidCallback onRecents;
  final VoidCallback onApprovals;

  @override
  Widget build(BuildContext context) {
    final user = dashboard.summary.user;
    final limits = dashboard.limits;
    final usage = dashboard.usage;

    return Column(
      children: [
        const TemplateStatusBar(),
        _SettingsHeader(onClose: onClose),
        const SectionCaption('Account'),
        SettingsGroup(
          children: [
            SettingsRow(
              icon: Icons.mail_outline_rounded,
              title: 'Email',
              value: user.email,
            ),
            SettingsRow(
              key: const Key('account-limits-card'),
              icon: Icons.add_box_outlined,
              title: 'Concurrent tasks',
              value:
                  '${limits.currentConcurrentTasks}/${limits.maxConcurrentTasks ?? '∞'}',
            ),
            SettingsRow(
              icon: Icons.query_stats_rounded,
              title: 'Usage',
              value: '${usage.totalTasks} tasks',
            ),
            SettingsRow(
              icon: Icons.storage_outlined,
              title: 'Data Controls',
              showChevron: true,
              onTap: onRepos,
            ),
            SettingsRow(
              icon: Icons.archive_outlined,
              title: 'Archived Chats',
              showChevron: true,
              onTap: onRecents,
            ),
            const SettingsRow(
              icon: Icons.book_outlined,
              title: 'Custom instructions',
              value: 'Not wired',
              showDivider: false,
            ),
          ],
        ),
        const SectionCaption('App'),
        const SettingsGroup(
          children: [
            SettingsRow(
              icon: Icons.wb_sunny_outlined,
              title: 'Color Scheme',
              value: 'Local only',
              showChevron: true,
            ),
            SettingsRow(
              icon: Icons.phone_iphone_rounded,
              title: 'Haptic Feedback',
              value: 'Local only',
              showDivider: false,
            ),
          ],
        ),
        const SectionCaption('Speech'),
        SettingsGroup(
          children: [
            SettingsRow(
              icon: Icons.graphic_eq_rounded,
              title: 'Voice',
              value: 'Not wired',
              showChevron: true,
              onTap: onApprovals,
            ),
            const SettingsRow(
              icon: Icons.language_rounded,
              title: 'Main Language',
              value: 'Not wired',
              showChevron: true,
              showDivider: false,
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(17, 8, 17, 0),
          child: Text(
            'Some template settings are placeholders until backend support exists.',
            style: TextStyle(
              color: TemplateColors.labelSecondary,
              fontSize: 13,
              height: 17 / 13,
            ),
          ),
        ),
        const SectionCaption('About'),
        const SettingsGroup(
          children: [
            SettingsRow(
              icon: Icons.help_outline_rounded,
              title: 'Help Center',
              value: 'Not wired',
            ),
            SettingsRow(
              icon: Icons.description_outlined,
              title: 'Terms of Use',
              value: 'Not wired',
            ),
            SettingsRow(
              icon: Icons.lock_outline_rounded,
              title: 'Privacy Policy',
              value: 'Not wired',
            ),
            SettingsRow(
              icon: Icons.storage_outlined,
              title: 'Phodex for iOS',
              value: '1.0.0',
              showDivider: false,
            ),
          ],
        ),
        const SizedBox(height: 22),
        SettingsGroup(
          children: [
            SettingsRow(
              icon: Icons.logout_rounded,
              title: 'Close settings',
              destructive: true,
              showDivider: false,
              onTap: onClose,
            ),
          ],
        ),
      ],
    );
  }
}

class _AccountError extends StatelessWidget {
  const _AccountError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TemplateStatusBar(),
        const SizedBox(height: 160),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: TemplateColors.labelSecondary),
        ),
        const SizedBox(height: 12),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Text(
            'Settings',
            style: TextStyle(
              color: Colors.black,
              fontSize: 17,
              height: 22 / 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          Positioned(
            right: 3,
            child: TemplateIcon(icon: Icons.close_rounded, onTap: onClose),
          ),
        ],
      ),
    );
  }
}
