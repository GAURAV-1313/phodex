import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/features/home/application/home_controller.dart';
import 'package:mobile/features/repos/application/repos_controller.dart';
import 'package:mobile/shared/theme/theme.dart';
import 'package:mobile/shared/widgets/stitch_ui.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _composer = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  Future<void> _submit([String? value]) async {
    final prompt = (value ?? _composer.text).trim();
    if (prompt.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    try {
      final task = await ref
          .read(homeTasksProvider.notifier)
          .createTask(prompt);
      _composer.clear();
      if (mounted) context.go('/session/${task.id}');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedProjectContextProvider).asData?.value;
    final tasks =
        ref.watch(homeTasksProvider).asData?.value ?? const <TaskSummary>[];
    TaskSummary? active;
    for (final task in tasks) {
      if (!task.status.isTerminal) {
        active = task;
        break;
      }
    }
    return StitchScaffold(
      key: const Key('home-screen'),
      active: StitchTab.home,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 112),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.bgInput,
                  child: Icon(Icons.person_outline),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good morning',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 10,
                            color: AppColors.accentSuccess,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Desktop runtime connected',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => context.push('/approvals'),
                  icon: const Badge(
                    smallSize: 8,
                    child: Icon(Icons.notifications_none_rounded, size: 30),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 72),
            const Text(
              'What should your AI\nengineer build today?',
              style: TextStyle(
                fontSize: 38,
                height: 1.13,
                letterSpacing: -1.5,
                color: Color(0xFFC3C4C9),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 54),
            Row(
              children: [
                _ContextPill(
                  label: 'Context',
                  icon: Icons.attach_file_rounded,
                  onTap: () => _pickRepository(context),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.auto_awesome, color: AppColors.accentPrimary),
                const SizedBox(width: 12),
                Expanded(
                  child: _RepositoryChip(
                    label: selected?.name ?? 'Select repository',
                    onTap: () => _pickRepository(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 46),
            const Text(
              'SUGGESTED FLOWS',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 1.3,
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _Suggestion(
                    label: 'Fix Bug',
                    icon: Icons.bug_report_outlined,
                    onTap: () => _submit(
                      'Inspect the current project, find the most important bug, and propose a focused fix.',
                    ),
                  ),
                  _Suggestion(
                    label: 'Review Code',
                    icon: Icons.rate_review_outlined,
                    onTap: () => _submit(
                      'Review the current codebase and report the highest-impact improvements.',
                    ),
                  ),
                  _Suggestion(
                    label: 'Plan Feature',
                    icon: Icons.auto_awesome_outlined,
                    onTap: () => _submit(
                      'Plan the requested feature, list affected files, and wait for approval before editing.',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 52),
            if (active != null)
              _CurrentTask(
                task: active,
                onTap: () => context.go('/session/${active!.id}'),
              ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 8, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(color: Color(0x0A000000), blurRadius: 24),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _composer,
                      minLines: 1,
                      maxLines: 4,
                      onSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(
                        hintText: 'Describe what you need built…',
                        filled: false,
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(fontSize: 17),
                    ),
                  ),
                  IconButton(
                    onPressed: _submitting ? null : () => _submit(),
                    icon: Icon(
                      _submitting
                          ? Icons.hourglass_top_rounded
                          : Icons.arrow_upward_rounded,
                    ),
                    color: Colors.white,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.accentPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickRepository(BuildContext context) async {
    final repos =
        ref.read(repositoriesProvider).asData?.value ??
        const <SyncedRepository>[];
    if (repos.isEmpty) {
      context.go('/repos');
      return;
    }
    final selected = await showModalBottomSheet<SyncedRepository>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RepositoryPicker(repos: repos),
    );
    if (selected != null)
      await ref
          .read(repositoriesProvider.notifier)
          .selectRepository(repoId: selected.id);
  }
}

class _ContextPill extends StatelessWidget {
  const _ContextPill({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ActionChip(
    onPressed: onTap,
    avatar: Icon(icon),
    label: Text(label, style: const TextStyle(fontSize: 17)),
    backgroundColor: Colors.white,
    shape: const StadiumBorder(),
  );
}

class _RepositoryChip extends StatelessWidget {
  const _RepositoryChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 18)],
      ),
      child: Row(
        children: [
          const Icon(Icons.terminal_rounded, color: AppColors.accentPrimary),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          const Icon(Icons.unfold_more_rounded, color: AppColors.textMuted),
        ],
      ),
    ),
  );
}

class _Suggestion extends StatelessWidget {
  const _Suggestion({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 10),
    child: ActionChip(
      onPressed: onTap,
      avatar: Icon(icon, color: AppColors.accentPrimary),
      label: Text(label, style: const TextStyle(fontSize: 16)),
      backgroundColor: Colors.white,
      shape: const StadiumBorder(),
    ),
  );
}

class _CurrentTask extends StatelessWidget {
  const _CurrentTask({required this.task, required this.onTap});
  final TaskSummary task;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => StitchCard(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CURRENT TASK',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          task.title ?? task.prompt,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 25,
            letterSpacing: -.7,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          task.currentPhase ?? 'Agent is working…',
          style: const TextStyle(fontSize: 17, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        LinearProgressIndicator(
          value: null,
          borderRadius: BorderRadius.circular(6),
        ),
      ],
    ),
  );
}

class _RepositoryPicker extends StatelessWidget {
  const _RepositoryPicker({required this.repos});
  final List<SyncedRepository> repos;
  @override
  Widget build(BuildContext context) => Container(
    height: MediaQuery.sizeOf(context).height * .78,
    padding: const EdgeInsets.all(28),
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 42,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.borderSubtle,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
        const SizedBox(height: 26),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Select Repository',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        const SizedBox(height: 18),
        TextField(
          decoration: InputDecoration(
            hintText: 'Search repositories…',
            prefixIcon: const Icon(Icons.search),
            fillColor: AppColors.bgInput,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.separated(
            itemCount: repos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final repo = repos[i];
              return StitchCard(
                onTap: () => Navigator.pop(context, repo),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F2FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.folder_outlined,
                        color: AppColors.accentPrimary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            repo.name,
                            style: const TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            repo.currentBranch ?? repo.defaultBranch ?? 'main',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.radio_button_unchecked,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}
