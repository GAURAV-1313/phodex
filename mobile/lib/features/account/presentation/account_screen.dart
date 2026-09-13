import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/core/network/server_connection_controller.dart';
import 'package:mobile/core/providers/repository_providers.dart';
import 'package:mobile/features/account/application/account_controller.dart';
import 'package:mobile/features/repos/application/repos_controller.dart';
import 'package:mobile/features/welcome/application/auth_controller.dart';
import 'package:mobile/features/welcome/application/onboarding_controller.dart';
import 'package:mobile/features/welcome/presentation/onboarding_nav.dart';
import 'package:mobile/shared/theme/theme.dart';
import 'package:mobile/shared/widgets/stitch_ui.dart';
import 'package:url_launcher/url_launcher.dart';

const _supportUrl = 'https://github.com/GAURAV-1313/phodex/issues/new';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  Future<void> _refresh(WidgetRef ref) {
    ref.invalidate(runtimeInfoProvider);
    return ref.read(accountDashboardProvider.notifier).refresh();
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    await ref.read(authControllerProvider.notifier).signOut();
    // The next sign-in may be a different account (or a different
    // runtime), so it walks through setup again.
    await ref.read(onboardingControllerProvider.notifier).reset();
    ref.invalidate(runtimeInfoProvider);
    if (context.mounted) context.go('/welcome');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(accountDashboardProvider);
    return StitchScaffold(
      key: const Key('account-screen'),
      active: StitchTab.account,
      child: RefreshIndicator(
        onRefresh: () => _refresh(ref),
        child: StitchAsyncView<AccountDashboard>(
          value: value,
          errorTitle: "Couldn't load your account",
          onRetry: () => _refresh(ref),
          builder: (context, dashboard) {
            final user = dashboard.summary.user;
            return ListView(
              padding: stitchScreenPadding,
              children: [
                StitchHeader(onBell: () => context.push('/approvals')),
                const SizedBox(height: AppSpacing.s32),
                Semantics(
                  header: true,
                  child: Text('Account', style: context.text.displayLarge),
                ),
                const SizedBox(height: AppSpacing.s24),
                _ProfileHeader(user: user),
                const SizedBox(height: AppSpacing.s32),
                _UsageCard(dashboard: dashboard),
                const SizedBox(height: AppSpacing.s32),
                const _RuntimeSection(),
                const SizedBox(height: AppSpacing.s32),
                const StitchSectionLabel('System settings'),
                StitchCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _SettingRow(
                        icon: Icons.smart_toy_outlined,
                        label: 'AI engine',
                        onTap: () => context.push('/account/ai-engine'),
                      ),
                      const Divider(height: 1),
                      _SettingRow(
                        icon: Icons.notifications_none_rounded,
                        label: 'Notifications',
                        onTap: () => context.push('/account/notifications'),
                      ),
                      const Divider(height: 1),
                      _SettingRow(
                        icon: Icons.palette_outlined,
                        label: 'Appearance',
                        onTap: () => _showAppearancePicker(context),
                      ),
                      const Divider(height: 1),
                      _SettingRow(
                        icon: Icons.lock_outline,
                        label: 'Privacy & security',
                        onTap: () => context.push('/account/sessions'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s24),
                StitchCard(
                  padding: EdgeInsets.zero,
                  child: _SettingRow(
                    icon: Icons.help_outline,
                    label: 'Support center',
                    onTap: () => _openSupportCenter(context),
                  ),
                ),
                const SizedBox(height: AppSpacing.s32),
                Center(
                  child: TextButton(
                    key: const Key('account-sign-out'),
                    onPressed: () => _signOut(context, ref),
                    child: Text(
                      'Sign out',
                      style: context.text.labelLarge?.copyWith(
                        color: context.colors.accentError,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),
                Center(
                  child: Text(
                    'Phodex local build',
                    style: context.text.labelMedium,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        CircleAvatar(
          radius: AppSpacing.s48,
          backgroundColor: colors.bgInput,
          child: Icon(
            Icons.person_outline,
            size: AppSpacing.s48,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.s16),
        Text(
          user.name,
          textAlign: TextAlign.center,
          style: context.text.titleLarge,
        ),
        const SizedBox(height: AppSpacing.s4),
        Text(
          user.email,
          textAlign: TextAlign.center,
          style: context.text.bodyMedium,
        ),
      ],
    );
  }
}

class _UsageCard extends StatelessWidget {
  const _UsageCard({required this.dashboard});

  final AccountDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return StitchCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StitchSectionLabel('Usage this month'),
          Text(
            '${dashboard.usage.totalTasks}',
            style: context.text.displayLarge?.copyWith(
              color: colors.accentPrimary,
            ),
          ),
          Text('Automated tasks', style: context.text.bodyLarge),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.s20),
            child: Divider(height: 1),
          ),
          const StitchSectionLabel('Current plan'),
          Text(
            dashboard.limits.maxConcurrentTasks == null
                ? 'Personal workspace'
                : 'Managed workspace',
            style: context.text.bodyLarge,
          ),
        ],
      ),
    );
  }
}

/// Which backend the app talks to, whether it's up, and the levers to
/// change that — the mobile-side counterpart of the onboarding choice.
class _RuntimeSection extends ConsumerWidget {
  const _RuntimeSection();

  Future<void> _forgetDesktop(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Forget this desktop?'),
        content: const Text(
          "You'll need to pair again before running tasks on it.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Forget'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(serverUrlProvider.notifier).forget();
    ref.invalidate(runtimeInfoProvider);
  }

  Future<void> _editGithubToken(
    BuildContext context,
    WidgetRef ref, {
    required bool configured,
  }) async {
    final changed = await showStitchSheet<bool>(
      context,
      title: 'GitHub token',
      child: _GithubTokenSheet(configured: configured),
    );
    if (changed == true) ref.invalidate(runtimeInfoProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final runtime = ref.watch(runtimeInfoProvider);
    final serverUrl = ref.watch(serverUrlProvider);
    final config = ref.watch(apiConfigProvider);
    final info = runtime.asData?.value;
    final url = serverUrl ?? config.baseUrl;
    final pairedDesktop =
        serverUrl != null &&
        serverUrl.isNotEmpty &&
        serverUrl != config.cloudBaseUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StitchSectionLabel('Runtime'),
        StitchCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.s20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (info != null)
                      Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: AppSpacing.s12,
                            color: info.runnerOnline
                                ? colors.accentSuccess
                                : colors.textMuted,
                          ),
                          const SizedBox(width: AppSpacing.s8),
                          Expanded(
                            child: Text(
                              '${info.runnerName} · '
                              '${info.runnerOnline ? 'Online' : 'Offline'}',
                              style: context.text.titleMedium,
                            ),
                          ),
                        ],
                      )
                    else if (runtime.hasError)
                      Text(
                        'Runtime status unavailable',
                        style: context.text.titleMedium,
                      )
                    else
                      Row(
                        children: [
                          const SizedBox(
                            width: AppSpacing.s12,
                            height: AppSpacing.s12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: AppSpacing.s8),
                          Text(
                            'Checking runtime…',
                            style: context.text.titleMedium,
                          ),
                        ],
                      ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.code(color: colors.textSecondary),
                    ),
                    if (info != null) ...[
                      const SizedBox(height: AppSpacing.s4),
                      Text(
                        info.isCloud
                            ? 'Hosted runner · ${info.workerEngine} engine'
                            : 'Your machine · ${info.workerEngine} engine',
                        style: context.text.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1),
              _SettingRow(
                icon: Icons.swap_horiz_rounded,
                label: 'Change runtime',
                onTap: () => _switchRuntime(
                  context,
                  ref,
                  '/runtime?from=${OnboardingFrom.account}',
                ),
              ),
              const Divider(height: 1),
              _SettingRow(
                icon: Icons.desktop_windows_outlined,
                label: 'Connect desktop',
                onTap: () => _switchRuntime(
                  context,
                  ref,
                  '/connect-desktop?from=${OnboardingFrom.account}',
                ),
              ),
              if (pairedDesktop) ...[
                const Divider(height: 1),
                _SettingRow(
                  icon: Icons.link_off_rounded,
                  label: 'Forget desktop',
                  onTap: () => _forgetDesktop(context, ref),
                ),
              ],
              if (info?.isCloud == true) ...[
                const Divider(height: 1),
                _SettingRow(
                  icon: Icons.key_outlined,
                  label: 'GitHub token',
                  trailing: info!.hasGithubToken
                      ? 'Configured'
                      : 'Not configured',
                  onTap: () => _editGithubToken(
                    context,
                    ref,
                    configured: info.hasGithubToken,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Save or clear the GitHub token Phodex Cloud uses to push from its
/// workspaces. Pops with `true` when something changed.
class _GithubTokenSheet extends ConsumerStatefulWidget {
  const _GithubTokenSheet({required this.configured});

  final bool configured;

  @override
  ConsumerState<_GithubTokenSheet> createState() => _GithubTokenSheetState();
}

class _GithubTokenSheetState extends ConsumerState<_GithubTokenSheet> {
  final _token = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _token.dispose();
    super.dispose();
  }

  Future<void> _submit(String? token) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final configured = await ref
          .read(repoRepositoryProvider)
          .saveGithubToken(token);
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            configured ? 'GitHub token saved' : 'GitHub token cleared',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = "Couldn't update the token. Try again.");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Used by Phodex Cloud to push branches to your repositories. '
          'A fine-grained personal access token with Contents read & write '
          'is enough.',
          style: context.text.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.s16),
        TextField(
          key: const Key('github-token-field'),
          controller: _token,
          obscureText: true,
          autocorrect: false,
          enableSuggestions: false,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Personal access token',
            hintText: 'github_pat_…',
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.s12),
          StatusBanner(message: _error!, tone: StatusTone.error),
        ],
        const SizedBox(height: AppSpacing.s16),
        StitchPrimaryButton(
          key: const Key('github-token-save'),
          label: 'Save token',
          loading: _busy,
          onPressed: () {
            final value = _token.text.trim();
            if (value.isEmpty) {
              setState(() => _error = 'Paste a token first.');
              return;
            }
            _submit(value);
          },
        ),
        if (widget.configured) ...[
          const SizedBox(height: AppSpacing.s4),
          TextButton(
            key: const Key('github-token-clear'),
            onPressed: _busy ? null : () => _submit(null),
            child: const Text('Clear stored token'),
          ),
        ],
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s12,
        ),
        child: Row(
          children: [
            Container(
              width: AppSpacing.s40,
              height: AppSpacing.s40,
              decoration: BoxDecoration(
                color: colors.bgInput,
                borderRadius: BorderRadius.circular(AppRadii.chip),
              ),
              child: Icon(icon, size: 20),
            ),
            const SizedBox(width: AppSpacing.s16),
            Expanded(child: Text(label, style: context.text.bodyLarge)),
            if (trailing != null) ...[
              Text(trailing!, style: context.text.bodySmall),
              const SizedBox(width: AppSpacing.s4),
            ],
            Icon(Icons.chevron_right, color: colors.textMuted),
          ],
        ),
      ),
    );
  }
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

void _showAppearancePicker(BuildContext context) {
  showStitchSheet<void>(
    context,
    title: 'Appearance',
    child: Consumer(
      builder: (sheetContext, ref, _) {
        final current = ref.watch(themeModeProvider);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final option in const [
              (ThemeMode.system, 'System', Icons.brightness_auto_outlined),
              (ThemeMode.light, 'Light', Icons.light_mode_outlined),
              (ThemeMode.dark, 'Dark', Icons.dark_mode_outlined),
            ])
              _AppearanceOption(
                label: option.$2,
                icon: option.$3,
                selected: current == option.$1,
                onTap: () {
                  ref.read(themeModeProvider.notifier).setThemeMode(option.$1);
                  Navigator.pop(sheetContext);
                },
              ),
          ],
        );
      },
    ),
  );
}

class _AppearanceOption extends StatelessWidget {
  const _AppearanceOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.button),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s8,
            vertical: AppSpacing.s12,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected ? colors.accentPrimary : colors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.s16),
              Expanded(
                child: Text(
                  label,
                  style: selected
                      ? context.text.titleMedium
                      : context.text.bodyLarge,
                ),
              ),
              if (selected)
                Icon(Icons.check_rounded, color: colors.accentPrimary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Runs one of the runtime detours (`/runtime` or `/connect-desktop` with
/// `?from=account`). If the backend address actually changed, the current
/// session belongs to the old backend, so it is ended and the user is sent
/// to sign in again — onboarding itself stays complete.
Future<void> _switchRuntime(
  BuildContext context,
  WidgetRef ref,
  String path,
) async {
  final before = ref.read(serverUrlProvider);
  final changed = await context.push<bool>(path);
  ref.invalidate(runtimeInfoProvider);
  final after = ref.read(serverUrlProvider);
  if (changed != true || after == before || after == null) return;
  ref.read(authControllerProvider.notifier).endSession();
  if (context.mounted) context.go('/sign-in');
}
