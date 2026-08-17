import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/features/repos/application/repos_controller.dart';
import 'package:mobile/shared/theme/theme.dart';
import 'package:mobile/shared/widgets/phodex_mascot.dart';
import 'package:mobile/shared/widgets/stagger_in.dart';
import 'package:mobile/shared/widgets/stitch_ui.dart';

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

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(repositoriesProvider);
    final selected = ref
        .watch(selectedProjectContextProvider)
        .asData
        ?.value
        ?.syncedRepositoryId;
    return StitchScaffold(
      active: StitchTab.repos,
      child: RefreshIndicator(
        onRefresh: () => ref.read(repositoriesProvider.notifier).refreshList(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, stitchDockClearance),
          children: [
            StitchHeader(onBell: () => context.push('/approvals')),
            const SizedBox(height: 44),
            Text(
              'Repositories',
              style: AppTypography.display(
                fontSize: AppTypeScale.displayLarge,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 28),
            TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v.trim()),
              decoration: InputDecoration(
                hintText: 'Search repositories…',
                prefixIcon: const Icon(Icons.search),
                fillColor: AppColors.bgInput,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 28),
            value.when(
              data: (repos) {
                final visible = _query.isEmpty
                    ? repos
                    : repos
                          .where(
                            (repo) => repo.name.toLowerCase().contains(
                              _query.toLowerCase(),
                            ),
                          )
                          .toList();
                if (repos.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: Column(
                      children: [
                        const PhodexMascot(size: 84, mood: MascotMood.curious),
                        const SizedBox(height: 24),
                        Text(
                          'No repositories yet',
                          style: AppTypography.display(
                            fontSize: AppTypeScale.title,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Open Phodex on your desktop and sync a workspace to get started.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: AppTypeScale.body,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                if (visible.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: Column(
                      children: [
                        const PhodexMascot(size: 84, mood: MascotMood.idle),
                        const SizedBox(height: 24),
                        Text(
                          'No matching repositories',
                          style: AppTypography.display(
                            fontSize: AppTypeScale.title,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Nothing named "$_query". Try a different search.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: AppTypeScale.body,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final (i, repo) in visible.indexed)
                      StaggerIn(
                        index: i,
                        child: _RepoCard(
                          repo: repo,
                          selected: repo.id == selected,
                          onTap: () => context.push('/repos/${repo.id}'),
                        ),
                      ),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(60),
                child: PhodexLoading(),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.only(top: 100),
                child: StitchErrorState(
                  title: "Couldn't load your repositories",
                  onRetry: () =>
                      ref.read(repositoriesProvider.notifier).refreshList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RepoCard extends StatelessWidget {
  const _RepoCard({
    required this.repo,
    required this.selected,
    required this.onTap,
  });
  final SyncedRepository repo;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: StitchCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F2FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.folder_outlined,
                  color: AppColors.accentPrimary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  repo.name,
                  style: const TextStyle(
                    fontSize: 27,
                    height: 1.05,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 22,
            runSpacing: 10,
            children: [
              _Meta(
                Icons.account_tree_outlined,
                repo.currentBranch ?? repo.defaultBranch ?? 'main',
              ),
              const _Meta(Icons.terminal_rounded, 'Local runtime'),
              _Meta(
                Icons.sync_rounded,
                repo.isActive ? 'In sync' : 'Needs sync',
                color: repo.isActive
                    ? AppColors.accentPrimary
                    : AppColors.accentError,
              ),
            ],
          ),
          if (selected)
            const Align(
              alignment: Alignment.centerRight,
              child: Chip(label: Text('Default')),
            ),
        ],
      ),
    ),
  );
}

class _Meta extends StatelessWidget {
  const _Meta(this.icon, this.label, {this.color = AppColors.textSecondary});
  final IconData icon;
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 18, color: color),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(fontSize: 16, color: color)),
    ],
  );
}

class RepositoryDetailScreen extends ConsumerWidget {
  const RepositoryDetailScreen({super.key, required this.repoId});
  final String repoId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repos =
        ref.watch(repositoriesProvider).asData?.value ??
        const <SyncedRepository>[];
    SyncedRepository? repo;
    for (final item in repos) {
      if (item.id == repoId) {
        repo = item;
        break;
      }
    }
    final selectedRepo = repo;
    if (selectedRepo == null) {
      return const Scaffold(body: PhodexLoading());
    }
    return StitchScaffold(
      active: StitchTab.repos,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, stitchDockClearance),
        children: [
          StitchHeader(
            title: 'Repository details',
            onBack: () => context.pop(),
          ),
          const SizedBox(height: 24),
          StitchCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedRepo.name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  selectedRepo.currentBranch ??
                      selectedRepo.defaultBranch ??
                      'main',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const Divider(height: 32),
                _DetailRow('Desktop runtime', selectedRepo.deviceId),
                _DetailRow(
                  'Sync status',
                  selectedRepo.isActive ? 'Connected' : 'Disconnected',
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          StitchPrimaryButton(
            label: 'Set as default',
            icon: Icons.check_circle_outline,
            onPressed: () async {
              await ref
                  .read(repositoriesProvider.notifier)
                  .selectRepository(repoId: selectedRepo.id);
              if (context.mounted) context.go('/home');
            },
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 15),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}
