import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/features/home/application/home_controller.dart';
import 'package:mobile/shared/theme/theme.dart';
import 'package:mobile/shared/widgets/phodex_mascot.dart';
import 'package:mobile/shared/widgets/stagger_in.dart';
import 'package:mobile/shared/widgets/stitch_ui.dart';

class RecentsScreen extends ConsumerStatefulWidget {
  const RecentsScreen({super.key});
  @override
  ConsumerState<RecentsScreen> createState() => _RecentsScreenState();
}

class _RecentsScreenState extends ConsumerState<RecentsScreen> {
  String _filter = 'All';
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

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(homeTasksProvider);
    return StitchScaffold(
      active: StitchTab.activity,
      child: RefreshIndicator(
        onRefresh: () => ref.read(homeTasksProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, stitchDockClearance),
          children: [
            StitchHeader(onBell: () => context.push('/approvals')),
            const SizedBox(height: 44),
            Text(
              'Activity',
              style: AppTypography.display(
                fontSize: AppTypeScale.displayLarge,
                letterSpacing: -1,
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: 28),
            TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v.trim()),
              decoration: InputDecoration(
                hintText: 'Search tasks…',
                prefixIcon: const Icon(Icons.search_rounded),
                fillColor: context.colors.bgInput,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: ['All', 'Running', 'Completed']
                  .map(
                    (filter) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: _filter == filter,
                          onSelected: (_) => setState(() => _filter = filter),
                          selectedColor: context.colors.bgCard,
                          backgroundColor: context.colors.bgInput,
                          shape: const StadiumBorder(),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 32),
            value.when(
              data: (tasks) {
                final visible = tasks
                    .where(
                      (task) =>
                          (_filter == 'All' ||
                              (_filter == 'Running'
                                  ? !task.status.isTerminal
                                  : task.status == TaskStatus.completed)) &&
                          (_query.isEmpty ||
                              (task.title ?? task.prompt)
                                  .toLowerCase()
                                  .contains(_query.toLowerCase())),
                    )
                    .toList();
                if (tasks.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: Column(
                      children: [
                        const PhodexMascot(size: 84, mood: MascotMood.idle),
                        const SizedBox(height: 24),
                        Text(
                          'No tasks yet',
                          style: AppTypography.display(
                            fontSize: AppTypeScale.title,
                            color: context.colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Describe what you need built and your agent will get to work.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: AppTypeScale.body,
                            color: context.colors.textSecondary,
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
                          'No matching tasks',
                          style: AppTypography.display(
                            fontSize: AppTypeScale.title,
                            color: context.colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _query.isNotEmpty
                              ? 'Nothing named "$_query". Try a different search.'
                              : 'No tasks match this filter yet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: AppTypeScale.body,
                            color: context.colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TODAY',
                      style: TextStyle(
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                        color: context.colors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 18),
                    for (final (i, task) in visible.indexed)
                      StaggerIn(
                        index: i,
                        child: _ActivityCard(
                          task: task,
                          onTap: () => context.go('/session/${task.id}'),
                        ),
                      ),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 120),
                child: PhodexLoading(),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.only(top: 80),
                child: StitchErrorState(
                  title: "Couldn't load your tasks",
                  onRetry: () => ref.read(homeTasksProvider.notifier).refresh(),
                ),
              ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              PhodexMascot(size: 52, mood: moodForTaskStatus(task.status)),
              Container(
                width: 2,
                height: 78,
                color: context.colors.borderSubtle,
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: StitchCard(
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.title ?? task.prompt,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _StatusPill(status: task.status),
                    ],
                  ),
                  Text(
                    live
                        ? (task.currentPhase ?? 'Agent is working')
                        : (task.finalSummary ??
                              task.errorMessage ??
                              task.status.value),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      color: context.colors.textSecondary,
                    ),
                  ),
                  if (live) ...[
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final TaskStatus status;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: taskStatusColor(context.colors, status.value),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(
      status.value.replaceAll('_', ' ').toUpperCase(),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
