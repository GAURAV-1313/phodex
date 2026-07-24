import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/features/session/application/session_controller.dart';
import 'package:mobile/features/session/application/session_state.dart';
import 'package:mobile/shared/theme/theme.dart';
import 'package:mobile/shared/widgets/stitch_ui.dart';

class SessionScreen extends ConsumerWidget {
  const SessionScreen({super.key, required this.taskId});
  final String taskId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(sessionProvider(taskId));
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: value.when(
          data: (session) => _ExecutionView(
            session: session,
            onApprove: (id) =>
                ref.read(sessionProvider(taskId).notifier).approve(id),
            onReject: (id) =>
                ref.read(sessionProvider(taskId).notifier).reject(id),
            onCancel: () =>
                ref.read(sessionProvider(taskId).notifier).cancelTask(),
            onReply: (message) =>
                ref.read(sessionProvider(taskId).notifier).sendReply(message),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              Center(child: Text('Could not load task: $error')),
        ),
      ),
    );
  }
}

class _ExecutionView extends StatefulWidget {
  const _ExecutionView({
    required this.session,
    required this.onApprove,
    required this.onReject,
    required this.onCancel,
    required this.onReply,
  });
  final SessionUiState session;
  final ValueChanged<String> onApprove;
  final ValueChanged<String> onReject;
  final VoidCallback onCancel;
  final ValueChanged<String> onReply;
  @override
  State<_ExecutionView> createState() => _ExecutionViewState();
}

class _ExecutionViewState extends State<_ExecutionView> {
  final _reply = TextEditingController();
  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.session.task;
    ApprovalRequest? approval;
    for (final item in widget.session.approvals) {
      if (item.status == ApprovalStatus.pending) {
        approval = item;
        break;
      }
    }
    final complete = task.status.isTerminal;
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 14, 28, 116),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => context.go('/activity'),
              icon: const Icon(Icons.chevron_left_rounded, size: 34),
            ),
            const Spacer(),
            const Text(
              'Phodex',
              style: TextStyle(fontSize: 27, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => _showLogs(context),
              icon: const Icon(Icons.terminal_rounded),
            ),
          ],
        ),
        const SizedBox(height: 45),
        Center(
          child: Column(
            children: [
              Text(
                complete ? task.status.value.toUpperCase() : 'EXECUTION LIVE',
                style: TextStyle(
                  letterSpacing: 2,
                  color: taskStatusColor(task.status.value),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                task.title ?? task.prompt,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 25,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                task.currentPhase ??
                    (complete ? 'Execution finished' : 'Your agent is working'),
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 42),
        if (!complete) const LinearProgressIndicator(),
        const SizedBox(height: 42),
        _Timeline(events: widget.session.events),
        if (approval != null)
          Padding(
            padding: const EdgeInsets.only(top: 26),
            child: _ApprovalBlock(
              approval: approval,
              busy: widget.session.isResolvingApproval,
              onApprove: () => widget.onApprove(approval!.id),
              onReject: () => widget.onReject(approval!.id),
            ),
          ),
        if (complete)
          _CompletionCard(task: task, messages: widget.session.messages),
        const SizedBox(height: 36),
        StitchPrimaryButton(
          label: complete ? 'Done' : 'View terminal logs',
          icon: complete ? null : Icons.terminal_rounded,
          onPressed: () =>
              complete ? context.go('/activity') : _showLogs(context),
        ),
        if (!complete) ...[
          TextButton(
            onPressed: widget.onCancel,
            child: const Text(
              'Cancel task',
              style: TextStyle(color: AppColors.accentError),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _reply,
                    decoration: const InputDecoration(
                      hintText: 'Message your agent',
                      border: InputBorder.none,
                      filled: false,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    final message = _reply.text.trim();
                    if (message.isNotEmpty) {
                      widget.onReply(message);
                      _reply.clear();
                    }
                  },
                  icon: const Icon(Icons.arrow_upward_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.accentPrimary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showLogs(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        _LogsSheet(events: widget.session.events, onCancel: widget.onCancel),
  );
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.events});
  final List<TaskEventEnvelope> events;
  @override
  Widget build(BuildContext context) {
    final steps = events
        .where((event) => event.type != 'task.log')
        .take(6)
        .toList();
    return Column(
      children: [
        for (final event in steps)
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.accentPrimary,
              child: const Icon(Icons.check_rounded, color: Colors.white),
            ),
            title: Text(
              event.data['message']?.toString() ??
                  event.type.replaceAll('.', ' '),
            ),
            subtitle: const Text('Execution event'),
          ),
      ],
    );
  }
}

class _ApprovalBlock extends StatelessWidget {
  const _ApprovalBlock({
    required this.approval,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });
  final ApprovalRequest approval;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  @override
  Widget build(BuildContext context) {
    final command = approval.payload['command']?.toString() ?? approval.title;
    return StitchCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HUMAN VERIFICATION NEEDED',
            style: TextStyle(
              letterSpacing: 1.1,
              color: Color(0xFF9A5A15),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            approval.title,
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 18),
          Text(
            '\$ $command',
            style: const TextStyle(
              fontFamily: 'monospace',
              color: AppColors.accentPrimary,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            approval.description,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: busy ? null : onReject,
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: busy ? null : onApprove,
                  child: Text(busy ? 'Resolving…' : 'Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompletionCard extends StatelessWidget {
  const _CompletionCard({required this.task, required this.messages});
  final TaskSummary task;
  final List<TaskMessage> messages;
  @override
  Widget build(BuildContext context) {
    final assistantMessages = messages
        .where((message) => message.role == TaskMessageRole.assistant)
        .toList();
    final summary =
        task.finalSummary ??
        task.errorMessage ??
        (assistantMessages.isEmpty
            ? 'Execution finished.'
            : assistantMessages.last.content);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: StitchCard(
        child: Column(
          children: [
            Icon(
              task.status == TaskStatus.completed
                  ? Icons.check_circle
                  : Icons.info_outline,
              size: 56,
              color: task.status == TaskStatus.completed
                  ? AppColors.accentSuccess
                  : AppColors.accentError,
            ),
            const SizedBox(height: 16),
            Text(
              summary,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogsSheet extends StatelessWidget {
  const _LogsSheet({required this.events, required this.onCancel});
  final List<TaskEventEnvelope> events;
  final VoidCallback onCancel;
  @override
  Widget build(BuildContext context) {
    final logs = events.where((event) => event.type == 'task.log').toList();
    return Container(
      height: MediaQuery.sizeOf(context).height * .76,
      padding: const EdgeInsets.all(22),
      decoration: const BoxDecoration(
        color: Color(0xFF171717),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Execution logs',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: ListView(
              children: [
                for (final log in logs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      log.data['message']?.toString() ?? log.type,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Color(0xFFD5D5D5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: onCancel,
                  child: const Text('Force terminate'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
