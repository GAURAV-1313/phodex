import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/features/approvals/application/approvals_controller.dart';
import 'package:mobile/features/repos/application/repos_controller.dart';
import 'package:mobile/shared/theme/theme.dart';
import 'package:mobile/shared/widgets/phodex_mascot.dart';
import 'package:mobile/shared/widgets/stagger_in.dart';
import 'package:mobile/shared/widgets/stitch_nav.dart';
import 'package:mobile/shared/widgets/stitch_ui.dart';

const _desktopSyncCopy =
    'Repo sync is metadata-only — no shell, file, or search access from your phone.';
const _cloudSyncCopy =
    'Cloud workspaces are cloned on Phodex Cloud and run there.';

class ReposScreen extends ConsumerStatefulWidget {
  const ReposScreen({super.key});
  @override
  ConsumerState<ReposScreen> createState() => _ReposScreenState();
}

class _ReposScreenState extends ConsumerState<ReposScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _openAddGithubSheet() async {
    final repo = await showStitchSheet<SyncedRepository>(
      context,
      title: 'Add GitHub repository',
      child: const _AddGithubRepoSheet(),
    );
    if (repo == null || !mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Connected ${repo.name}')));
  }

  Future<void> _useRepository(SyncedRepository repo) async {
    try {
      await ref
          .read(repositoriesProvider.notifier)
          .selectRepository(repoId: repo.id);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Couldn't switch to ${repo.name}"),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => _useRepository(repo),
          ),
        ),
      );
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Now working in ${repo.name}')));
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(repositoriesProvider);
    final repos = value.asData?.value;
    final selectedId = ref
        .watch(selectedProjectContextProvider)
        .asData
        ?.value
        ?.syncedRepositoryId;
    final runtime = ref.watch(runtimeInfoProvider).asData?.value;
    final isCloud = runtime?.isCloud ?? false;
    final hasPendingApprovals =
        (ref.watch(approvalsProvider).asData?.value ?? const []).isNotEmpty;

    return StitchScaffold(
      active: StitchTab.repos,
      child: RefreshIndicator(
        onRefresh: () => ref.read(repositoriesProvider.notifier).refreshList(),
        child: ListView(
          padding: stitchScreenPadding,
          children: [
            StitchHeader(
              bellBadge: hasPendingApprovals,
              onBell: () => context.push('/approvals'),
            ),
            const SizedBox(height: AppSpacing.s32),
            Text('Repositories', style: context.text.displayLarge),
            const SizedBox(height: AppSpacing.s24),
            _OverviewCard(
              runnerName: runtime?.runnerName ?? 'Desktop',
              isCloud: isCloud,
              syncedCount: repos?.length,
              activeCount: repos?.where((repo) => repo.isActive).length,
            ),
            const SizedBox(height: AppSpacing.s16),
            if (isCloud) ...[
              StitchSecondaryButton(
                label: 'Add GitHub repository',
                icon: Icons.add_rounded,
                onPressed: _openAddGithubSheet,
              ),
              const SizedBox(height: AppSpacing.s16),
            ],
            TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v.trim()),
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Search repositories…',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.s24),
            StitchAsyncView<List<SyncedRepository>>(
              value: value,
              errorTitle: "Couldn't load your repositories",
              onRetry: () =>
                  ref.read(repositoriesProvider.notifier).refreshList(),
              isEmpty: (repos) => repos.isEmpty,
              empty: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.s32),
                child: isCloud
                    ? StitchEmptyState(
                        mood: MascotMood.curious,
                        title: 'No repos synced yet',
                        message:
                            'Connect a GitHub repository and Phodex Cloud will clone it into a workspace.',
                        actionLabel: 'Add GitHub repository',
                        onAction: _openAddGithubSheet,
                      )
                    : StitchEmptyState(
                        mood: MascotMood.curious,
                        title: 'No repos synced yet',
                        message:
                            'Run the Phodex device agent on your desktop to sync your projects.',
                        actionLabel: 'Connect desktop',
                        onAction: () =>
                            context.push('/connect-desktop?from=account'),
                      ),
              ),
              builder: (context, repos) {
                final query = _query.toLowerCase();
                final visible = query.isEmpty
                    ? repos
                    : repos
                          .where(
                            (repo) => repo.name.toLowerCase().contains(query),
                          )
                          .toList();
                if (visible.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.s32),
                    child: StitchEmptyState(
                      mood: MascotMood.resting,
                      title: 'No matching repositories',
                      message:
                          'Nothing named "$_query". Try a different search.',
                      actionLabel: 'Clear search',
                      onAction: () {
                        _search.clear();
                        setState(() => _query = '');
                      },
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final (i, repo) in visible.indexed)
                      StaggerIn(
                        index: i,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppSpacing.s16,
                          ),
                          child: _RepoCard(
                            repo: repo,
                            isCurrent: repo.id == selectedId,
                            onTap: () => context.push('/repos/${repo.id}'),
                            onUse: () => _useRepository(repo),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.runnerName,
    required this.isCloud,
    required this.syncedCount,
    required this.activeCount,
  });

  final String runnerName;
  final bool isCloud;
  final int? syncedCount;
  final int? activeCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return StitchCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.s12),
                decoration: BoxDecoration(
                  color: colors.accentPrimarySoft,
                  borderRadius: BorderRadius.circular(AppRadii.chip),
                ),
                child: Icon(
                  isCloud ? Icons.cloud_outlined : Icons.computer_outlined,
                  color: colors.accentPrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      runnerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleMedium,
                    ),
                    Text(
                      isCloud ? 'Phodex Cloud runtime' : 'Desktop runtime',
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          Row(
            children: [
              _Stat(label: 'Synced', value: syncedCount),
              const SizedBox(width: AppSpacing.s32),
              _Stat(label: 'Active', value: activeCount),
              const Spacer(),
              const Chip(
                avatar: Icon(Icons.sync_rounded),
                label: Text('Metadata sync'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          Text(
            isCloud ? _cloudSyncCopy : _desktopSyncCopy,
            style: context.text.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final int? value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value?.toString() ?? '–', style: context.text.headlineSmall),
      Text(label.toUpperCase(), style: context.text.labelSmall),
    ],
  );
}

/// Small metadata pill in the [ContextPill] family — branch, device, sync
/// state — so a repo card's facts read as one row of the same shape.
class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
    this.color,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final Color? color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fg = color ?? colors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s8 - AppSpacing.s2,
      ),
      decoration: BoxDecoration(
        color: filled
            ? fg.withValues(alpha: colors.isDark ? .18 : .12)
            : colors.bgInput,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: AppSpacing.s4),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelMedium?.copyWith(color: fg),
            ),
          ),
        ],
      ),
    );
  }
}

class _RepoCard extends StatelessWidget {
  const _RepoCard({
    required this.repo,
    required this.isCurrent,
    required this.onTap,
    required this.onUse,
  });

  final SyncedRepository repo;
  final bool isCurrent;
  final VoidCallback onTap;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return StitchCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  repo.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleLarge,
                ),
              ),
              if (repo.isCloud) ...[
                const SizedBox(width: AppSpacing.s8),
                _MetaPill(
                  icon: Icons.cloud_outlined,
                  label: 'Cloud',
                  color: colors.accentPrimary,
                  filled: true,
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [
              _MetaPill(
                icon: Icons.account_tree_outlined,
                label: repo.currentBranch ?? repo.defaultBranch ?? 'main',
              ),
              _MetaPill(
                icon: repo.isCloud
                    ? Icons.cloud_outlined
                    : Icons.computer_outlined,
                label: repo.deviceName,
              ),
              if (!repo.isActive)
                _MetaPill(
                  icon: Icons.sync_problem_rounded,
                  label: 'Needs sync',
                  color: colors.accentWarning,
                  filled: true,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          StitchTerminalBlock(text: repo.gitRoot, maxLines: 1),
          const SizedBox(height: AppSpacing.s12),
          Row(
            children: [
              Expanded(
                child: Text(
                  repo.lastScannedAt == null
                      ? 'Not synced yet'
                      : 'Synced ${relativeTime(repo.lastScannedAt!)}',
                  style: context.text.labelMedium,
                ),
              ),
              if (isCurrent)
                _MetaPill(
                  icon: Icons.check_rounded,
                  label: 'Active',
                  color: colors.accentSuccess,
                  filled: true,
                )
              else
                FilledButton(onPressed: onUse, child: const Text('Use')),
            ],
          ),
        ],
      ),
    );
  }
}

/// "just now", "6 min ago", "3 h ago", "2 d ago".
String relativeTime(DateTime time) {
  final delta = DateTime.now().toUtc().difference(time.toUtc());
  if (delta.inMinutes < 1) return 'just now';
  if (delta.inHours < 1) return '${delta.inMinutes} min ago';
  if (delta.inDays < 1) return '${delta.inHours} h ago';
  return '${delta.inDays} d ago';
}

class _AddGithubRepoSheet extends ConsumerStatefulWidget {
  const _AddGithubRepoSheet();

  @override
  ConsumerState<_AddGithubRepoSheet> createState() =>
      _AddGithubRepoSheetState();
}

class _AddGithubRepoSheetState extends ConsumerState<_AddGithubRepoSheet> {
  final _url = TextEditingController();
  final _branch = TextEditingController();
  final _token = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _url.dispose();
    _branch.dispose();
    _token.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final url = _url.text.trim();
    if (url.isEmpty) {
      setState(() => _error = 'Enter the GitHub repository URL to connect.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final branch = _branch.text.trim();
      final token = _token.text.trim();
      final repo = await ref
          .read(repositoriesProvider.notifier)
          .connectGithubRepository(
            url: url,
            branch: branch.isEmpty ? null : branch,
            token: token.isEmpty ? null : token,
          );
      if (!mounted) return;
      Navigator.pop(context, repo);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error =
            "Couldn't connect this repository. Check the URL and token, then try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Phodex Cloud clones the repository into a workspace and runs tasks there.',
        style: context.text.bodyMedium,
      ),
      const SizedBox(height: AppSpacing.s16),
      TextField(
        key: const Key('github-url-field'),
        controller: _url,
        autofocus: true,
        enabled: !_busy,
        keyboardType: TextInputType.url,
        autocorrect: false,
        textInputAction: TextInputAction.next,
        decoration: const InputDecoration(
          labelText: 'Repository URL',
          hintText: 'https://github.com/owner/repo',
        ),
      ),
      const SizedBox(height: AppSpacing.s12),
      TextField(
        key: const Key('github-branch-field'),
        controller: _branch,
        enabled: !_busy,
        autocorrect: false,
        textInputAction: TextInputAction.next,
        decoration: const InputDecoration(
          labelText: 'Branch (optional)',
          hintText: 'main',
        ),
      ),
      const SizedBox(height: AppSpacing.s12),
      TextField(
        key: const Key('github-token-field'),
        controller: _token,
        enabled: !_busy,
        obscureText: true,
        autocorrect: false,
        enableSuggestions: false,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _connect(),
        decoration: const InputDecoration(
          labelText: 'Access token (optional)',
          helperText:
              'Fine-grained personal access token with Contents: read & write; stored encrypted',
          helperMaxLines: 2,
        ),
      ),
      if (_error case final error?) ...[
        const SizedBox(height: AppSpacing.s16),
        StatusBanner(tone: StatusTone.error, message: error),
      ],
      const SizedBox(height: AppSpacing.s20),
      StitchPrimaryButton(
        label: 'Connect',
        icon: Icons.link_rounded,
        loading: _busy,
        onPressed: _connect,
      ),
    ],
  );
}

class RepositoryDetailScreen extends ConsumerWidget {
  const RepositoryDetailScreen({super.key, required this.repoId});
  final String repoId;

  Future<void> _setDefault(
    BuildContext context,
    WidgetRef ref,
    SyncedRepository repo,
  ) async {
    try {
      await ref
          .read(repositoriesProvider.notifier)
          .selectRepository(repoId: repo.id);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Couldn't switch to ${repo.name}"),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => _setDefault(context, ref, repo),
          ),
        ),
      );
      return;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Now working in ${repo.name}')));
    stitchPopOrGo(context, '/repos');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(repositoriesProvider);
    final selectedId = ref
        .watch(selectedProjectContextProvider)
        .asData
        ?.value
        ?.syncedRepositoryId;

    SyncedRepository? find(List<SyncedRepository> repos) {
      for (final repo in repos) {
        if (repo.id == repoId) return repo;
      }
      return null;
    }

    final known = value.asData?.value;
    final title = (known == null ? null : find(known)?.name) ?? 'Repository';

    return StitchScaffold(
      showDock: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.screenTop,
              AppSpacing.screen,
              0,
            ),
            child: StitchHeader(
              title: title,
              onBack: () => stitchPopOrGo(context, '/repos'),
            ),
          ),
          Expanded(
            child: StitchAsyncView<List<SyncedRepository>>(
              value: value,
              errorTitle: "Couldn't load this repository",
              onRetry: () =>
                  ref.read(repositoriesProvider.notifier).refreshList(),
              builder: (context, repos) {
                final repo = find(repos);
                if (repo == null) {
                  return StitchErrorState(
                    title: 'Repository not found',
                    message:
                        'It may have been removed or synced from another device.',
                    onRetry: () =>
                        ref.read(repositoriesProvider.notifier).refreshList(),
                  );
                }
                return _RepositoryDetails(
                  repo: repo,
                  isCurrent: repo.id == selectedId,
                  onSetDefault: () => _setDefault(context, ref, repo),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RepositoryDetails extends StatelessWidget {
  const _RepositoryDetails({
    required this.repo,
    required this.isCurrent,
    required this.onSetDefault,
  });

  final SyncedRepository repo;
  final bool isCurrent;
  final VoidCallback onSetDefault;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListView(
      padding: stitchScreenPaddingNoDock,
      children: [
        Wrap(
          spacing: AppSpacing.s8,
          runSpacing: AppSpacing.s8,
          children: [
            if (repo.isCloud)
              _MetaPill(
                icon: Icons.cloud_outlined,
                label: 'Cloud',
                color: colors.accentPrimary,
                filled: true,
              ),
            _MetaPill(
              icon: Icons.account_tree_outlined,
              label: repo.currentBranch ?? repo.defaultBranch ?? 'main',
            ),
            _MetaPill(
              icon: repo.isCloud
                  ? Icons.cloud_outlined
                  : Icons.computer_outlined,
              label: repo.deviceName,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s16),
        StitchTerminalBlock(text: repo.gitRoot, label: 'Path'),
        const SizedBox(height: AppSpacing.s16),
        StitchCard(
          child: Column(
            children: [
              _DetailRow('Current branch', repo.currentBranch ?? '–'),
              _DetailRow('Default branch', repo.defaultBranch ?? '–'),
              _DetailRow(repo.isCloud ? 'Runs on' : 'Device', repo.deviceName),
              if (repo.isCloud)
                _DetailRow('GitHub', repo.remoteUrl ?? '–', mono: true),
              _DetailRow(
                'Last synced',
                repo.lastScannedAt == null
                    ? 'Never'
                    : relativeTime(repo.lastScannedAt!),
              ),
              _DetailRow(
                'Sync status',
                repo.isActive ? 'Connected' : 'Needs sync',
                color: repo.isActive
                    ? colors.accentSuccess
                    : colors.accentWarning,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s24),
        if (isCurrent)
          const StatusBanner(
            tone: StatusTone.success,
            message: 'This is the repository new tasks run in.',
          )
        else
          StitchPrimaryButton(
            label: 'Set as default',
            icon: Icons.check_circle_outline,
            onPressed: onSetDefault,
          ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value, {this.color, this.mono = false});
  final String label;
  final String value;
  final Color? color;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: context.text.bodyMedium)),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: mono
                  ? AppTypography.code(color: color ?? colors.textPrimary)
                  : context.text.titleSmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
