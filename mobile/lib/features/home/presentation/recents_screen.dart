import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/features/home/application/home_controller.dart';
import 'package:mobile/shared/theme/theme.dart';
import 'package:mobile/shared/widgets/stitch_ui.dart';

class RecentsScreen extends ConsumerStatefulWidget {
  const RecentsScreen({super.key});
  @override
  ConsumerState<RecentsScreen> createState() => _RecentsScreenState();
}

class _RecentsScreenState extends ConsumerState<RecentsScreen> {
  String _filter = 'All';
  @override
  Widget build(BuildContext context) {
    final value = ref.watch(homeTasksProvider);
    return StitchScaffold(
      active: StitchTab.activity,
      child: RefreshIndicator(
        onRefresh: () => ref.read(homeTasksProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 110),
          children: [
            StitchHeader(
              title: 'Phodex',
              onBell: () => context.push('/approvals'),
            ),
            const SizedBox(height: 30),
            const Text(
              'Activity',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search tasks…',
                prefixIcon: const Icon(Icons.search_rounded),
                fillColor: AppColors.bgInput,
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
                          selectedColor: Colors.white,
                          backgroundColor: AppColors.bgInput,
                          shape: const StadiumBorder(),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 32),
            const Text(
              'TODAY',
              style: TextStyle(
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 18),
            value.when(
              data: (tasks) {
                final visible = tasks
                    .where(
                      (task) =>
                          _filter == 'All' ||
                          (_filter == 'Running'
                              ? !task.status.isTerminal
                              : task.status == TaskStatus.completed),
                    )
                    .toList();
                if (visible.isEmpty)
                  return const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(
                      child: Text(
                        'Your agent has no work to show yet.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  );
                return Column(
                  children: [
                    for (final task in visible)
                      _ActivityCard(
                        task: task,
                        onTap: () => context.go('/session/${task.id}'),
                      ),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 120),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.only(top: 80),
                child: Text('Could not load activity: $e'),
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
    final color = taskStatusColor(task.status.value);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(
                  live ? Icons.smart_toy_outlined : Icons.check_rounded,
                  color: Colors.white,
                ),
              ),
              Container(width: 2, height: 78, color: AppColors.borderSubtle),
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
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      color: AppColors.textSecondary,
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
      color: taskStatusColor(status.value),
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
