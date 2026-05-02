import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/features/repos/application/repos_controller.dart';
import 'package:mobile/shared/widgets/template_kit.dart';

class ReposScreen extends ConsumerWidget {
  const ReposScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reposValue = ref.watch(repositoriesProvider);
    final selectedContext = ref
        .watch(selectedProjectContextProvider)
        .asData
        ?.value;
    final selectedRepoId = selectedContext?.syncedRepositoryId;

    return TemplateScaffold(
      key: const Key('repos-screen'),
      bottomSafeArea: true,
      child: RefreshIndicator(
        onRefresh: () => ref.read(repositoriesProvider.notifier).refreshList(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(25, 0, 25, 28),
          children: [
            const TemplateStatusBar(),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Connected repositories',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 34,
                      height: 41 / 34,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TemplateIcon(
                  icon: Icons.close_rounded,
                  onTap: () => context.go('/home'),
                ),
              ],
            ),
            const SizedBox(height: 26),
            const _SupportItem(
              icon: Icons.sync_rounded,
              title: 'Sync stays local',
              body:
                  'Repositories are metadata synced by your companion device. Pull to refresh after syncing.',
            ),
            const SizedBox(height: 20),
            reposValue.when(
              data: (repos) {
                if (repos.isEmpty) {
                  return const _EmptyRepos();
                }
                return Column(
                  children: [
                    for (final repo in repos)
                      _RepositoryCard(
                        repo: repo,
                        selected: repo.id == selectedRepoId,
                        onTap: () async {
                          await ref
                              .read(repositoriesProvider.notifier)
                              .selectRepository(repoId: repo.id);
                          if (context.mounted) {
                            context.go('/home');
                          }
                        },
                      ),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 96),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => _ErrorBlock(
                message: 'Could not load repositories: $error',
                onRetry: () =>
                    ref.read(repositoriesProvider.notifier).refreshList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportItem extends StatelessWidget {
  const _SupportItem({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.black, size: 24),
        const SizedBox(width: 25),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 17,
                  height: 22 / 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: const TextStyle(
                  color: TemplateColors.labelSecondary,
                  fontSize: 17,
                  height: 22 / 17,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RepositoryCard extends StatelessWidget {
  const _RepositoryCard({
    required this.repo,
    required this.selected,
    required this.onTap,
  });

  final SyncedRepository repo;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFE7F8EE)
              : TemplateColors.promptBackground,
          borderRadius: BorderRadius.circular(14),
          border: selected ? Border.all(color: const Color(0xFF34C759)) : null,
        ),
        child: Row(
          children: [
            const PhodexBadge(size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    repo.name,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 17,
                      height: 22 / 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${repo.currentBranch ?? repo.defaultBranch ?? 'no branch'} • ${repo.gitRoot}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: TemplateColors.labelSecondary,
                      fontSize: 15,
                      height: 20 / 15,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_rounded, color: Color(0xFF34C759)),
          ],
        ),
      ),
    );
  }
}

class _EmptyRepos extends StatelessWidget {
  const _EmptyRepos();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 100),
      child: Text(
        'No synced repositories yet. Start the companion sync, then pull to refresh.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: TemplateColors.labelSecondary,
          fontSize: 17,
          height: 22 / 17,
        ),
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 96),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: TemplateColors.labelSecondary),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
