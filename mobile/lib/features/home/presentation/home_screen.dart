import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/features/home/application/home_controller.dart';
import 'package:mobile/features/repos/application/repos_controller.dart';
import 'package:mobile/shared/theme/theme.dart';
import 'package:mobile/shared/widgets/phodex_mascot.dart';
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(homeTasksProvider.notifier).revalidate(),
    );
  }

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
    final tasksAsync = ref.watch(homeTasksProvider);
    final tasks = tasksAsync.asData?.value ?? const <TaskSummary>[];
    TaskSummary? active;
    for (final task in tasks) {
      if (!task.status.isTerminal) {
        active = task;
        break;
      }
    }
    final isConnected = tasksAsync.hasValue;
    final mascotMood = !isConnected
        ? MascotMood.error
        : active == null
        ? MascotMood.idle
        : active.status == TaskStatus.waitingApproval
        ? MascotMood.curious
        : MascotMood.thinking;
    return StitchScaffold(
      key: const Key('home-screen'),
      active: StitchTab.home,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, stitchDockClearance),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PhodexMascot(size: 44, mood: mascotMood),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Good morning',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 10,
                            color: isConnected
                                ? context.colors.accentSuccess
                                : context.colors.accentWarning,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isConnected
                                ? 'Desktop runtime connected'
                                : 'Reconnecting…',
                            style: TextStyle(
                              color: context.colors.textSecondary,
                            ),
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
            const SizedBox(height: 44),
            Text.rich(
              TextSpan(
                style: AppTypography.display(
                  fontSize: 36,
                  height: 1.12,
                  letterSpacing: -0.6,
                  color: context.colors.textPrimary,
                ),
                children: [
                  const TextSpan(text: 'What should your '),
                  TextSpan(
                    text: 'AI engineer',
                    style: TextStyle(color: context.colors.accentPrimary),
                  ),
                  const TextSpan(text: ' build today?'),
                ],
              ),
            ),
            const SizedBox(height: 40),
            _RepositoryBar(
              label: selected?.name ?? 'Select repository',
              onTap: () => _pickRepository(context),
            ),
            const SizedBox(height: 40),
            Text(
              'SUGGESTED FLOWS',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: context.colors.textMuted,
                letterSpacing: 1.3,
              ),
            ),
            const SizedBox(height: 16),
            _FadingRow(
              children: [
                _Suggestion(
                  label: 'Fix Bug',
                  icon: Icons.bug_report_rounded,
                  onTap: () => _submit(
                    'Inspect the current project, find the most important bug, and propose a focused fix.',
                  ),
                ),
                _Suggestion(
                  label: 'Review Code',
                  icon: Icons.difference_outlined,
                  onTap: () => _submit(
                    'Review the current codebase and report the highest-impact improvements.',
                  ),
                ),
                _Suggestion(
                  label: 'Plan Feature',
                  icon: Icons.route_outlined,
                  onTap: () => _submit(
                    'Plan the requested feature, list affected files, and wait for approval before editing.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),
            if (active != null)
              _CurrentTask(
                task: active,
                onTap: () => context.go('/session/${active!.id}'),
              ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 8, 12),
              decoration: BoxDecoration(
                color: context.colors.bgCard,
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
                      backgroundColor: context.colors.accentPrimary,
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
    if (selected != null) {
      await ref
          .read(repositoriesProvider.notifier)
          .selectRepository(repoId: selected.id);
    }
  }
}

/// A single cohesive control for task setup — attaching context and picking
/// a repository used to be two disconnected elements (a pill, an orphan
/// decorative icon, then a separate elevated chip); this reads as one
/// deliberate unit instead.
/// Picks which synced repository the agent works against for the next task.
class _RepositoryBar extends StatelessWidget {
  const _RepositoryBar({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: context.colors.bgCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 18)],
      ),
      child: Row(
        children: [
          Icon(
            Icons.folder_outlined,
            size: 20,
            color: context.colors.accentPrimary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          Icon(
            Icons.unfold_more_rounded,
            size: 18,
            color: context.colors.textMuted,
          ),
        ],
      ),
    ),
  );
}

/// Horizontally scrolling row whose trailing edge fades to transparent
/// instead of clipping content mid-pill, signalling there's more to scroll to.
class _FadingRow extends StatelessWidget {
  const _FadingRow({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ShaderMask(
    shaderCallback: (bounds) => const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Colors.white, Colors.white, Colors.transparent],
      stops: [0, 0.88, 1],
    ).createShader(bounds),
    blendMode: BlendMode.dstIn,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(right: 24),
      child: Row(children: children),
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
      avatar: Icon(icon, color: context.colors.accentPrimary),
      label: Text(label, style: const TextStyle(fontSize: 16)),
      backgroundColor: context.colors.bgCard,
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
        Text(
          'CURRENT TASK',
          style: TextStyle(
            fontSize: AppTypeScale.micro,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: context.colors.textSecondary,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          task.title ?? task.prompt,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.display(
            fontSize: AppTypeScale.title,
            letterSpacing: -.5,
            color: context.colors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          task.currentPhase ?? 'Agent is working…',
          style: TextStyle(fontSize: 17, color: context.colors.textSecondary),
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
    decoration: BoxDecoration(
      color: context.colors.bgSurface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 42,
            height: 5,
            decoration: BoxDecoration(
              color: context.colors.borderSubtle,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
        const SizedBox(height: 26),
        Row(
          children: [
            Expanded(
              child: Text(
                'Select Repository',
                style: AppTypography.display(
                  fontSize: AppTypeScale.headline,
                  color: context.colors.textPrimary,
                ),
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
            fillColor: context.colors.bgInput,
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
                        color: context.colors.accentPrimarySoft,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.folder_outlined,
                        color: context.colors.accentPrimary,
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
                            style: TextStyle(
                              color: context.colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.radio_button_unchecked,
                      color: context.colors.textMuted,
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
