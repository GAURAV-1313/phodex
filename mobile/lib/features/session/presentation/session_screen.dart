import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/core/providers/repository_providers.dart';
import 'package:mobile/features/session/application/session_controller.dart';
import 'package:mobile/features/session/application/session_state.dart';
import 'package:mobile/shared/theme/theme.dart';
import 'package:mobile/shared/widgets/issue_card.dart';
import 'package:mobile/shared/widgets/phodex_mascot.dart';
import 'package:mobile/shared/widgets/stagger_in.dart';
import 'package:mobile/shared/widgets/stitch_ui.dart';

class SessionScreen extends ConsumerWidget {
  const SessionScreen({super.key, required this.taskId});
  final String taskId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(sessionProvider(taskId));
    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      body: SafeArea(
        child: value.when(
          data: (session) => _ExecutionView(
            session: session,
            onApprove: (id) =>
                ref.read(sessionProvider(taskId).notifier).approve(id),
            onReject: (id, {note}) => ref
                .read(sessionProvider(taskId).notifier)
                .reject(id, note: note),
            onCancel: () =>
                ref.read(sessionProvider(taskId).notifier).cancelTask(),
            onReply: (message) =>
                ref.read(sessionProvider(taskId).notifier).sendReply(message),
            onPrepareCommit: () => ref
                .read(gitOpsRepositoryProvider)
                .prepareCommit(taskId: taskId),
            onConfirmCommit: (gitOperationId, commitMessage) => ref
                .read(gitOpsRepositoryProvider)
                .confirmCommit(
                  taskId: taskId,
                  gitOperationId: gitOperationId,
                  commitMessage: commitMessage,
                ),
            onDiscardCommit: (gitOperationId) => ref
                .read(gitOpsRepositoryProvider)
                .discardCommit(taskId: taskId, gitOperationId: gitOperationId),
            onContinueWithNewTask: (prompt) => ref
                .read(sessionProvider(taskId).notifier)
                .continueWithNewTask(prompt),
          ),
          loading: () => const PhodexLoading(),
          error: (error, _) => StitchErrorState(
            title: "Couldn't load this task",
            onRetry: () => ref.invalidate(sessionProvider(taskId)),
          ),
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
    required this.onPrepareCommit,
    required this.onConfirmCommit,
    required this.onDiscardCommit,
    required this.onContinueWithNewTask,
  });
  final SessionUiState session;
  final ValueChanged<String> onApprove;
  final void Function(String approvalId, {String? note}) onReject;
  final VoidCallback onCancel;
  final ValueChanged<String> onReply;
  final Future<GitOperation> Function() onPrepareCommit;
  final Future<GitOperation> Function(
    String gitOperationId,
    String commitMessage,
  )
  onConfirmCommit;
  final Future<GitOperation> Function(String gitOperationId) onDiscardCommit;
  final Future<TaskSummary?> Function(String prompt) onContinueWithNewTask;
  @override
  State<_ExecutionView> createState() => _ExecutionViewState();
}

class _ExecutionViewState extends State<_ExecutionView> {
  final _reply = TextEditingController();
  bool _preparingCommit = false;
  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _startCommitFlow(BuildContext context) async {
    setState(() => _preparingCommit = true);
    GitOperation operation;
    try {
      operation = await widget.onPrepareCommit();
    } catch (e) {
      if (!context.mounted) return;
      setState(() => _preparingCommit = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not prepare commit: $e')));
      return;
    }
    if (!context.mounted) return;
    setState(() => _preparingCommit = false);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommitPushSheet(
        operation: operation,
        onConfirm: widget.onConfirmCommit,
        onDiscard: widget.onDiscardCommit,
      ),
    );
  }

  Future<void> _startFollowUpTask(BuildContext context) async {
    final newTaskId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _FollowUpTaskSheet(onSubmit: widget.onContinueWithNewTask),
    );
    if (newTaskId != null && context.mounted) {
      context.go('/session/$newTaskId');
    }
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
            IconButton(
              onPressed: () => _showLogs(context),
              icon: const Icon(Icons.terminal_rounded),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Center(
          child: Column(
            children: [
              PhodexMascot(size: 64, mood: moodForTaskStatus(task.status)),
              const SizedBox(height: 18),
              Text(
                complete ? task.status.value.toUpperCase() : 'EXECUTION LIVE',
                style: TextStyle(
                  letterSpacing: 2,
                  color: taskStatusColor(context.colors, task.status.value),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                task.title ?? task.prompt,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.display(
                  fontSize: 24,
                  height: 1.2,
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                task.currentPhase ??
                    (complete ? 'Execution finished' : 'Your agent is working'),
                style: TextStyle(
                  fontSize: 16,
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 42),
        if (!complete) const LinearProgressIndicator(),
        const SizedBox(height: 34),
        _Timeline(
          events: widget.session.events,
          onShowAll: () => _showLogs(context),
        ),
        if (approval != null)
          Padding(
            padding: const EdgeInsets.only(top: 26),
            child: _ApprovalBlock(
              approval: approval,
              busy: widget.session.isResolvingApproval,
              onApprove: () => widget.onApprove(approval!.id),
              onReject: () async {
                final reason = await showRejectReasonDialog(context);
                if (reason == null) return;
                widget.onReject(
                  approval!.id,
                  note: reason.isEmpty ? null : reason,
                );
              },
            ),
          ),
        if (complete)
          _CompletionCard(task: task, messages: widget.session.messages),
        if (complete && widget.session.issues.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              children: [
                for (final issue in widget.session.issues)
                  IssueCard(issue: issue),
              ],
            ),
          ),
        const SizedBox(height: 36),
        if (complete && task.status == TaskStatus.completed) ...[
          SizedBox(
            height: 56,
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _preparingCommit
                  ? null
                  : () => _startCommitFlow(context),
              icon: _preparingCommit
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_rounded, size: 18),
              label: Text(
                _preparingCommit ? 'Checking for changes…' : 'Commit & Push',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.colors.accentPrimary,
                side: BorderSide(color: context.colors.accentPrimary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (complete) ...[
          StitchPrimaryButton(
            label: 'Done',
            onPressed: () => context.go('/activity'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => _startFollowUpTask(context),
            child: const Text('Start a follow-up task'),
          ),
        ] else
          SizedBox(
            height: 50,
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showLogs(context),
              icon: const Icon(Icons.terminal_rounded, size: 18),
              label: const Text('View terminal logs'),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.colors.textSecondary,
                side: BorderSide(color: context.colors.borderSubtle),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        if (!complete) ...[
          TextButton(
            onPressed: widget.onCancel,
            child: Text(
              'Cancel task',
              style: TextStyle(color: context.colors.accentError),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
            decoration: BoxDecoration(
              color: context.colors.bgCard,
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
                    backgroundColor: context.colors.accentPrimary,
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

(IconData, Color) _timelineIconFor(AppColors colors, String eventType) =>
    switch (eventType) {
      'task.starting' => (
        Icons.play_circle_outline_rounded,
        colors.accentPrimary,
      ),
      'task.running' => (Icons.autorenew_rounded, colors.accentPrimary),
      'task.completed' => (Icons.check_circle_rounded, colors.accentSuccess),
      'task.failed' => (Icons.error_rounded, colors.accentError),
      'task.cancelled' => (Icons.stop_circle_rounded, colors.textMuted),
      'task.progress' => (Icons.circle, colors.textMuted),
      'git.started' => (Icons.upload_rounded, colors.accentPrimary),
      'git.completed' => (Icons.check_circle_rounded, colors.accentSuccess),
      'git.failed' => (Icons.error_rounded, colors.accentError),
      'git.discarded' => (Icons.stop_circle_rounded, colors.textMuted),
      _ => (Icons.circle, colors.textMuted),
    };

String _capitalize(String value) =>
    value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);

class _Timeline extends StatelessWidget {
  const _Timeline({required this.events, required this.onShowAll});
  final List<TaskEventEnvelope> events;
  final VoidCallback onShowAll;

  static const int _visibleCap = 6;

  @override
  Widget build(BuildContext context) {
    // Raw per-line log output (agent stdout, git command output) belongs in
    // the "Execution logs" sheet, not the milestone timeline — otherwise a
    // verbose git push floods this list and the "+N more steps" button
    // opens a sheet that doesn't even show the events that caused it.
    final steps = events
        .where((event) => event.type != 'task.log' && event.type != 'git.log')
        .toList();
    final visible = steps.take(_visibleCap).toList();
    final remaining = steps.length - visible.length;
    final timeFormat = DateFormat.Hm();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, event) in visible.indexed)
          StaggerIn(
            key: ValueKey(event.eventId),
            index: i,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Builder(
                    builder: (context) {
                      final (icon, color) = _timelineIconFor(
                        context.colors,
                        event.type,
                      );
                      final isDot =
                          event.type == 'task.progress' ||
                          !{
                            'task.starting',
                            'task.running',
                            'task.completed',
                            'task.failed',
                            'task.cancelled',
                            'git.started',
                            'git.completed',
                            'git.failed',
                            'git.discarded',
                          }.contains(event.type);
                      return Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        child: Icon(icon, size: isDot ? 8 : 18, color: color),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _capitalize(
                        event.data['message']?.toString() ??
                            event.type.replaceAll('.', ' '),
                      ),
                      style: const TextStyle(fontSize: 15.5, height: 1.35),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    timeFormat.format(event.timestamp.toLocal()),
                    style: TextStyle(
                      fontSize: 12,
                      color: context.colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (remaining > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 34),
            child: TextButton(
              onPressed: onShowAll,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
                alignment: Alignment.centerLeft,
              ),
              child: Text(
                '+$remaining more steps',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.colors.accentPrimary,
                ),
              ),
            ),
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
          Text(
            'HUMAN VERIFICATION NEEDED',
            style: TextStyle(
              letterSpacing: 1.1,
              color: context.colors.accentWarning,
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
            style: AppTypography.code(color: context.colors.accentPrimary),
          ),
          const SizedBox(height: 18),
          Text(
            approval.description,
            style: TextStyle(color: context.colors.textSecondary),
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

class _CommitPushSheet extends StatefulWidget {
  const _CommitPushSheet({
    required this.operation,
    required this.onConfirm,
    required this.onDiscard,
  });
  final GitOperation operation;
  final Future<GitOperation> Function(
    String gitOperationId,
    String commitMessage,
  )
  onConfirm;
  final Future<GitOperation> Function(String gitOperationId) onDiscard;

  @override
  State<_CommitPushSheet> createState() => _CommitPushSheetState();
}

class _CommitPushSheetState extends State<_CommitPushSheet> {
  late final _message = TextEditingController(
    text: widget.operation.commitMessage,
  );
  late GitOperation _operation = widget.operation;
  bool _busy = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  bool get _resolved =>
      _operation.status == GitOperationStatus.completed ||
      _operation.status == GitOperationStatus.failed;

  Future<void> _confirm() async {
    setState(() => _busy = true);
    try {
      final resolved = await widget.onConfirm(
        _operation.id,
        _message.text.trim(),
      );
      setState(() {
        _operation = resolved;
        _busy = false;
      });
    } catch (e) {
      setState(() => _busy = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Commit & push failed: $e')));
    }
  }

  Future<void> _discard() async {
    setState(() => _busy = true);
    await widget.onDiscard(_operation.id);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: 20),
          if (_resolved) ...[
            Icon(
              _operation.status == GitOperationStatus.completed
                  ? Icons.check_circle
                  : Icons.error_outline,
              size: 48,
              color: _operation.status == GitOperationStatus.completed
                  ? context.colors.accentSuccess
                  : context.colors.accentError,
            ),
            const SizedBox(height: 14),
            Text(
              _operation.status == GitOperationStatus.completed
                  ? 'Pushed to GitHub'
                  : "Couldn't push",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            if (_operation.errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _operation.errorMessage!,
                style: TextStyle(color: context.colors.textSecondary),
              ),
            ],
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: StitchPrimaryButton(
                label: 'Close',
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ] else ...[
            const Text(
              'Commit & push to GitHub',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _message,
              decoration: const InputDecoration(labelText: 'Commit message'),
            ),
            const SizedBox(height: 16),
            if ((_operation.statusOutput ?? '').isNotEmpty) ...[
              Text(
                'CHANGES',
                style: TextStyle(
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w700,
                  color: context.colors.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 160),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.colors.bgInput,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _operation.statusOutput ?? '',
                    style: AppTypography.code(
                      fontSize: 13,
                      color: context.colors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : _discard,
                    child: const Text('Discard'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _busy ? null : _confirm,
                    child: Text(_busy ? 'Pushing…' : 'Commit & push'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _FollowUpTaskSheet extends StatefulWidget {
  const _FollowUpTaskSheet({required this.onSubmit});
  final Future<TaskSummary?> Function(String prompt) onSubmit;

  @override
  State<_FollowUpTaskSheet> createState() => _FollowUpTaskSheetState();
}

class _FollowUpTaskSheetState extends State<_FollowUpTaskSheet> {
  final _prompt = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _prompt.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final prompt = _prompt.text.trim();
    if (prompt.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    try {
      final task = await widget.onSubmit(prompt);
      if (!mounted) return;
      if (task != null) {
        Navigator.pop(context, task.id);
      } else {
        setState(() => _submitting = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not start task: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: 20),
          const Text(
            'Start a follow-up task',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _prompt,
            autofocus: true,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Describe what you need built next…',
            ),
          ),
          const SizedBox(height: 16),
          StitchPrimaryButton(
            label: _submitting ? 'Starting…' : 'Start task',
            onPressed: _submitting ? null : _submit,
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
                  ? context.colors.accentSuccess
                  : context.colors.accentError,
            ),
            const SizedBox(height: 16),
            Text(
              summary,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                height: 1.5,
                color: context.colors.textSecondary,
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
    final logs = events
        .where((event) => event.type == 'task.log' || event.type == 'git.log')
        .toList();
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
                      style: AppTypography.code(color: const Color(0xFFD5D5D5)),
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
