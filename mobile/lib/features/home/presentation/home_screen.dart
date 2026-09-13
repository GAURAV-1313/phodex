import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/features/approvals/application/approvals_controller.dart';
import 'package:mobile/features/home/application/home_controller.dart';
import 'package:mobile/features/repos/application/repos_controller.dart';
import 'package:mobile/shared/theme/theme.dart';
import 'package:mobile/shared/widgets/phodex_mascot.dart';
import 'package:mobile/shared/widgets/stagger_in.dart';
import 'package:mobile/shared/widgets/stitch_ui.dart';

/// Starter prompts offered as chips; the first one also backs the empty
/// state's "Try an example" action.
const homeSuggestions = <({String label, IconData icon, String prompt})>[
  (
    label: 'Fix Bug',
    icon: Icons.bug_report_rounded,
    prompt:
        'Inspect the current project, find the most important bug, and propose a focused fix.',
  ),
  (
    label: 'Review Code',
    icon: Icons.difference_outlined,
    prompt:
        'Review the current codebase and report the highest-impact improvements.',
  ),
  (
    label: 'Plan Feature',
    icon: Icons.route_outlined,
    prompt:
        'Plan the requested feature, list affected files, and wait for approval before editing.',
  ),
];

/// How many recent tasks the home screen lists before pointing at Activity.
const _recentTaskLimit = 5;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _composer = TextEditingController();
  final _composerFocus = FocusNode();
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
    _composerFocus.dispose();
    super.dispose();
  }

  Future<void> _submit([String? value]) async {
    final prompt = (value ?? _composer.text).trim();
    if (prompt.isEmpty || _submitting) return;
    // Never create a task without a project context — the composer is
    // disabled in that case, but a chip or a stale tap must not slip through.
    final selected = ref.read(selectedProjectContextProvider).asData?.value;
    if (selected == null) return;
    setState(() => _submitting = true);
    try {
      final task = await ref
          .read(homeTasksProvider.notifier)
          .createTask(prompt);
      _composer.clear();
      if (mounted) context.push('/session/${task.id}');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Couldn't start the task"),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => _submit(prompt),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _fillExample() {
    _composer.text = homeSuggestions.first.prompt;
    _composer.selection = TextSelection.collapsed(
      offset: _composer.text.length,
    );
    _composerFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final selected = ref.watch(selectedProjectContextProvider).asData?.value;
    final repos =
        ref.watch(repositoriesProvider).asData?.value ??
        const <SyncedRepository>[];
    final tasksAsync = ref.watch(homeTasksProvider);
    final tasks = tasksAsync.asData?.value ?? const <TaskSummary>[];
    final pendingApprovals =
        ref.watch(approvalsProvider).asData?.value ?? const <ApprovalRequest>[];
    final runtime = ref.watch(runtimeInfoProvider).asData?.value;

    TaskSummary? active;
    for (final task in tasks) {
      if (!task.status.isTerminal) {
        active = task;
        break;
      }
    }
    final hasContext = selected != null;
    final hasPendingApprovals =
        pendingApprovals.isNotEmpty ||
        tasks.any((task) => task.status == TaskStatus.waitingApproval);
    final runnerName = runtime?.runnerName ?? 'your runtime';
    final runtimeOffline = runtime != null && !runtime.runnerOnline;
    final mascotMood = tasksAsync.hasError || runtimeOffline
        ? MascotMood.error
        : active == null
        ? MascotMood.idle
        : active.status == TaskStatus.waitingApproval
        ? MascotMood.curious
        : MascotMood.thinking;
    final contextLabel = hasContext
        ? describeProjectContext(selected, repos)
        : null;
    final canCompose = hasContext && !_submitting;

    return StitchScaffold(
      key: const Key('home-screen'),
      active: StitchTab.home,
      child: SingleChildScrollView(
        padding: stitchScreenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StitchHeader(
              mood: mascotMood,
              bellBadge: hasPendingApprovals,
              onBell: () => context.push('/approvals'),
            ),
            if (runtimeOffline) ...[
              const SizedBox(height: AppSpacing.s16),
              StatusBanner(
                tone: StatusTone.warning,
                message: '$runnerName is offline',
                actionLabel: 'Runtime',
                onAction: () => context.go('/account'),
              ),
            ] else if (tasksAsync.hasError) ...[
              const SizedBox(height: AppSpacing.s16),
              StatusBanner(
                tone: StatusTone.warning,
                busy: true,
                message: 'Reconnecting to $runnerName…',
                actionLabel: 'Runtime',
                onAction: () => context.go('/account'),
              ),
            ],
            const SizedBox(height: AppSpacing.s32),
            Text.rich(
              TextSpan(
                style: context.text.displayMedium,
                children: [
                  const TextSpan(text: 'What should your '),
                  TextSpan(
                    text: 'AI engineer',
                    style: context.text.displayMedium?.copyWith(
                      color: colors.accentPrimary,
                    ),
                  ),
                  const TextSpan(text: ' build today?'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s24),
            if (!hasContext) ...[
              StatusBanner(
                tone: StatusTone.info,
                message: 'Choose a repository before starting a task',
                actionLabel: 'Repos',
                onAction: () => context.push('/repos'),
              ),
              const SizedBox(height: AppSpacing.s12),
            ],
            ComposerBar(
              controller: _composer,
              focusNode: _composerFocus,
              hint: 'Describe what you need built…',
              enabled: hasContext,
              sending: _submitting,
              onSend: hasContext ? _submit : null,
              context: contextLabel == null
                  ? ContextPill(
                      name: 'Pick a repository',
                      emphasized: true,
                      onTap: () => context.push('/repos'),
                    )
                  : ContextPill(
                      name: contextLabel.name,
                      branch: contextLabel.branch,
                      onTap: () => context.push('/repos'),
                    ),
            ),
            const SizedBox(height: AppSpacing.s32),
            const StitchSectionLabel('Suggested flows'),
            _FadingRow(
              children: [
                for (final suggestion in homeSuggestions)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.s8),
                    child: ActionChip(
                      avatar: Icon(
                        suggestion.icon,
                        color: canCompose
                            ? colors.accentPrimary
                            : colors.textMuted,
                      ),
                      label: Text(suggestion.label),
                      onPressed: canCompose
                          ? () => _submit(suggestion.prompt)
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.s32),
            if (active != null) ...[
              _CurrentTask(
                task: active,
                onTap: () => context.push('/session/${active!.id}'),
              ),
              const SizedBox(height: AppSpacing.s24),
            ],
            StitchSectionLabel(
              'Recent tasks',
              trailing: tasks.length > _recentTaskLimit
                  ? TextButton(
                      onPressed: () => context.go('/activity'),
                      child: const Text('See all'),
                    )
                  : null,
            ),
            StitchAsyncView<List<TaskSummary>>(
              value: tasksAsync,
              errorTitle: "Couldn't load your tasks",
              onRetry: () => ref.read(homeTasksProvider.notifier).refresh(),
              isEmpty: (tasks) => tasks.isEmpty,
              empty: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s24),
                child: StitchEmptyState(
                  mood: MascotMood.curious,
                  title: 'No tasks yet',
                  message:
                      'Describe what you need built and Phodex will get to work.',
                  actionLabel: 'Try an example',
                  onAction: _fillExample,
                ),
              ),
              builder: (context, tasks) => Column(
                children: [
                  for (final (i, task) in tasks.take(_recentTaskLimit).indexed)
                    StaggerIn(
                      index: i,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                        child: _TaskRow(
                          task: task,
                          onTap: () => context.push('/session/${task.id}'),
                        ),
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
}

/// Horizontally scrolling row whose trailing edge fades to transparent
/// instead of clipping content mid-chip, signalling there's more to scroll.
class _FadingRow extends StatelessWidget {
  const _FadingRow({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    // Only the alpha matters for a dstIn mask, so any opaque token works.
    final opaque = context.colors.textPrimary;
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [opaque, opaque, opaque.withValues(alpha: 0)],
        stops: const [0, 0.88, 1],
      ).createShader(bounds),
      blendMode: BlendMode.dstIn,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(right: AppSpacing.s24),
        child: Row(children: children),
      ),
    );
  }
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
        StitchSectionLabel(
          'Current task',
          trailing: TaskStatusChip(
            status: task.status.value,
            compact: true,
            pulse: task.status != TaskStatus.waitingApproval,
          ),
        ),
        Text(
          task.title ?? task.prompt,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: context.text.titleLarge,
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          task.currentPhase == null
              ? 'Agent is working…'
              : task.currentPhase!.replaceAll('_', ' '),
          style: context.text.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.s16),
        LinearProgressIndicator(
          value: task.status == TaskStatus.waitingApproval ? 1 : null,
          borderRadius: BorderRadius.circular(AppRadii.chip),
        ),
      ],
    ),
  );
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task, required this.onTap});
  final TaskSummary task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final live = !task.status.isTerminal;
    final subtitle = live
        ? (task.currentPhase?.replaceAll('_', ' ') ?? 'Agent is working')
        : (task.finalSummary ?? task.errorMessage ?? 'Finished');
    return StitchCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title ?? task.prompt,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleSmall,
                ),
                const SizedBox(height: AppSpacing.s2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          TaskStatusChip(status: task.status.value, compact: true),
        ],
      ),
    );
  }
}
