import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/features/approvals/application/approvals_controller.dart';
import 'package:mobile/features/home/application/home_controller.dart';
import 'package:mobile/shared/theme/theme.dart';
import 'package:mobile/shared/widgets/phodex_mascot.dart';
import 'package:mobile/shared/widgets/stagger_in.dart';
import 'package:mobile/shared/widgets/stitch_ui.dart';

enum _Filter {
  all('All'),
  running('Running'),
  completed('Completed');

  const _Filter(this.label);
  final String label;

  bool matches(TaskSummary task) => switch (this) {
    _Filter.all => true,
    _Filter.running => !task.status.isTerminal,
    _Filter.completed => task.status == TaskStatus.completed,
  };
}

class RecentsScreen extends ConsumerStatefulWidget {
  const RecentsScreen({super.key});
  @override
  ConsumerState<RecentsScreen> createState() => _RecentsScreenState();
}

class _RecentsScreenState extends ConsumerState<RecentsScreen> {
  _Filter _filter = _Filter.all;
  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(homeTasksProvider.notifier).revalidate(),
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _clearFilters() {
    _search.clear();
    setState(() {
      _query = '';
      _filter = _Filter.all;
    });
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(homeTasksProvider);
    final hasPendingApprovals =
        (ref.watch(approvalsProvider).asData?.value ?? const []).isNotEmpty;
    return StitchScaffold(
      active: StitchTab.activity,
      child: RefreshIndicator(
        onRefresh: () => ref.read(homeTasksProvider.notifier).refresh(),
        child: ListView(
          padding: stitchScreenPadding,
          children: [
            StitchHeader(
              bellBadge: hasPendingApprovals,
              onBell: () => context.push('/approvals'),
            ),
            const SizedBox(height: AppSpacing.s32),
            Text('Activity', style: context.text.displayLarge),
            const SizedBox(height: AppSpacing.s24),
            TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v.trim()),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search tasks…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _search.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s8,
              children: [
                for (final filter in _Filter.values)
                  ChoiceChip(
                    label: Text(filter.label),
                    selected: _filter == filter,
                    onSelected: (_) => setState(() => _filter = filter),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.s24),
            StitchAsyncView<List<TaskSummary>>(
              value: value,
              errorTitle: "Couldn't load your tasks",
              onRetry: () => ref.read(homeTasksProvider.notifier).refresh(),
              isEmpty: (tasks) => tasks.isEmpty,
              empty: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.s48),
                child: StitchEmptyState(
                  mood: MascotMood.curious,
                  title: 'No tasks yet',
                  message:
                      'Describe what you need built and Phodex will get to work.',
                  actionLabel: 'Create your first coding task',
                  onAction: () => context.go('/home'),
                ),
              ),
              builder: (context, tasks) {
                final query = _query.toLowerCase();
                final visible = tasks
                    .where(
                      (task) =>
                          _filter.matches(task) &&
                          (query.isEmpty ||
                              (task.title ?? task.prompt)
                                  .toLowerCase()
                                  .contains(query) ||
                              task.prompt.toLowerCase().contains(query)),
                    )
                    .toList();
                if (visible.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.s48),
                    child: StitchEmptyState(
                      mood: MascotMood.resting,
                      title: 'No matching tasks',
                      message: _query.isNotEmpty
                          ? 'Nothing named "$_query". Try a different search.'
                          : 'No tasks match this filter yet.',
                      actionLabel: 'Clear filters',
                      onAction: _clearFilters,
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StitchSectionLabel(
                      '${visible.length} ${visible.length == 1 ? 'task' : 'tasks'}',
                    ),
                    for (final (i, task) in visible.indexed)
                      StaggerIn(
                        index: i,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppSpacing.s12,
                          ),
                          child: _ActivityCard(
                            task: task,
                            onTap: () => context.push('/session/${task.id}'),
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

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.task, required this.onTap});
  final TaskSummary task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final live = !task.status.isTerminal;
    final when = DateFormat.MMMd().add_Hm().format(task.updatedAt.toLocal());
    return StitchCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  task.title ?? task.prompt,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleMedium,
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              TaskStatusChip(status: task.status.value, compact: true),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            live
                ? (task.currentPhase?.replaceAll('_', ' ') ??
                      'Agent is working')
                : (task.finalSummary ??
                      task.errorMessage ??
                      taskStatusLabel(task.status.value)),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(when, style: context.text.labelMedium),
          if (live) ...[
            const SizedBox(height: AppSpacing.s12),
            LinearProgressIndicator(
              value: task.status == TaskStatus.waitingApproval ? 1 : null,
              borderRadius: BorderRadius.circular(AppRadii.chip),
            ),
          ],
        ],
      ),
    );
  }
}
