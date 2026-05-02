import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/features/home/application/home_controller.dart';
import 'package:mobile/shared/widgets/template_kit.dart';

class RecentsScreen extends ConsumerWidget {
  const RecentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksValue = ref.watch(homeTasksProvider);

    return TemplateScaffold(
      key: const Key('recents-screen'),
      backgroundColor: TemplateColors.groupedBackground,
      bottomSafeArea: true,
      child: RefreshIndicator(
        onRefresh: () => ref.read(homeTasksProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(17, 0, 17, 24),
          children: [
            const TemplateStatusBar(),
            const SizedBox(height: 4),
            _RecentsHeader(onOpenAccount: () => context.go('/account')),
            const SizedBox(height: 26),
            tasksValue.when(
              data: (tasks) {
                if (tasks.isEmpty) {
                  return const _EmptyRecents();
                }
                return Column(
                  children: [
                    for (final task in tasks)
                      _RecentConversation(
                        task: task,
                        onTap: () => context.go('/session/${task.id}'),
                      ),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 96),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => _ErrorBlock(
                message: 'Could not load recents: $error',
                onRetry: () => ref.read(homeTasksProvider.notifier).refresh(),
              ),
            ),
            const SizedBox(height: 24),
            _NewChatButton(onTap: () => context.go('/home')),
          ],
        ),
      ),
    );
  }
}

class _RecentsHeader extends StatelessWidget {
  const _RecentsHeader({required this.onOpenAccount});

  final VoidCallback onOpenAccount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Phodex',
          style: TextStyle(
            color: Colors.black,
            fontSize: 34,
            height: 41 / 34,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onOpenAccount,
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(19),
            ),
            child: const Row(
              children: [
                Icon(Icons.search_rounded, size: 21),
                SizedBox(width: 10),
                CircleAvatar(
                  radius: 13,
                  backgroundColor: Color(0xFFE7902F),
                  child: Text(
                    'G',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RecentConversation extends StatelessWidget {
  const _RecentConversation({required this.task, required this.onTap});

  final TaskSummary task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = (task.title ?? task.prompt).trim();
    final subtitle =
        task.finalSummary ??
        task.errorMessage ??
        task.currentPhase ??
        task.status.value;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            _StatusDot(status: task.status),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.isEmpty ? 'Untitled task' : title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 17,
                      height: 22 / 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
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
          ],
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});

  final TaskStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      TaskStatus.completed => const Color(0xFF34C759),
      TaskStatus.failed => const Color(0xFFFF3B30),
      TaskStatus.cancelled => TemplateColors.labelSecondary,
      TaskStatus.waitingApproval => const Color(0xFFFF9500),
      _ => Colors.black,
    };
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _EmptyRecents extends StatelessWidget {
  const _EmptyRecents();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 120),
      child: Center(
        child: Text(
          'No conversations yet',
          style: TextStyle(
            color: TemplateColors.labelSecondary,
            fontSize: 17,
            height: 22 / 17,
          ),
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
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: TemplateColors.labelSecondary,
              fontSize: 15,
              height: 20 / 15,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _NewChatButton extends StatelessWidget {
  const _NewChatButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(25),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit_outlined, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Chat',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  height: 22 / 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
