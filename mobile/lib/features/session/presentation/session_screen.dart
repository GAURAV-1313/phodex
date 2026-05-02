import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/features/session/application/session_controller.dart';
import 'package:mobile/features/session/application/session_state.dart';
import 'package:mobile/shared/widgets/template_kit.dart';

class SessionScreen extends ConsumerStatefulWidget {
  const SessionScreen({super.key, required this.taskId});

  final String taskId;

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  final _replyController = TextEditingController();

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    final reply = _replyController.text.trim();
    if (reply.isEmpty) {
      return;
    }
    _replyController.clear();
    final current = ref.read(sessionProvider(widget.taskId)).asData?.value;
    final controller = ref.read(sessionProvider(widget.taskId).notifier);
    if (current != null && current.task.status.isTerminal) {
      final nextTask = await controller.continueWithNewTask(reply);
      if (nextTask != null && mounted) {
        context.go('/session/${nextTask.id}');
      }
      return;
    }

    await controller.sendReply(reply);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final sessionValue = ref.watch(sessionProvider(widget.taskId));

    return TemplateScaffold(
      key: const Key('session-screen'),
      child: Stack(
        children: [
          Positioned.fill(
            child: sessionValue.when(
              data: (session) => _SessionTimeline(
                session: session,
                bottomPadding: bottomInset + 172,
                onRefresh: () =>
                    ref.read(sessionProvider(widget.taskId).notifier).refresh(),
                onApprove: (approvalId) => ref
                    .read(sessionProvider(widget.taskId).notifier)
                    .approve(approvalId),
                onReject: (approvalId) => ref
                    .read(sessionProvider(widget.taskId).notifier)
                    .reject(approvalId),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _SessionError(
                message: 'Could not load session: $error',
                onRetry: () =>
                    ref.read(sessionProvider(widget.taskId).notifier).refresh(),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _FrostedTopBar(
              onOpenRecents: () => context.go('/home/recents'),
              onOpenHome: () => context.go('/home'),
              onOpenAccount: () => context.go('/account'),
            ),
          ),
          Positioned(
            left: 16,
            right: 0,
            bottom: bottomInset + 82,
            child: PromptExamples(
              onPromptTap: () {
                _replyController.text =
                    'Design a database schema for an online merch store.';
              },
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: bottomInset + 20,
            child: _ReplyComposer(
              controller: _replyController,
              session: sessionValue.asData?.value,
              onSend: _sendReply,
              onCancel: () => ref
                  .read(sessionProvider(widget.taskId).notifier)
                  .cancelTask(),
              onRepos: () => context.go('/repos'),
              onApprovals: () => context.go('/approvals'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionTimeline extends StatelessWidget {
  const _SessionTimeline({
    required this.session,
    required this.bottomPadding,
    required this.onRefresh,
    required this.onApprove,
    required this.onReject,
  });

  final SessionUiState session;
  final double bottomPadding;
  final VoidCallback onRefresh;
  final ValueChanged<String> onApprove;
  final ValueChanged<String> onReject;

  @override
  Widget build(BuildContext context) {
    final pendingApprovals = session.approvals
        .where((approval) => approval.status == ApprovalStatus.pending)
        .toList();
    final userMessages = session.messages
        .where((message) => message.role == TaskMessageRole.user)
        .toList();
    final assistantMessages = session.messages
        .where((message) => message.role != TaskMessageRole.user)
        .toList();
    final eventResult = _latestAgentMessage(session.events);
    final completedResponse = _completedResponse(
      task: session.task,
      eventResult: eventResult,
      assistantMessages: assistantMessages,
    );

    return ListView(
      key: const Key('session-timeline'),
      padding: EdgeInsets.fromLTRB(16, 118, 16, bottomPadding),
      children: [
        for (final message in userMessages) ...[
          ChatMessageBlock(
            author: 'You',
            assistant: false,
            body: message.content,
          ),
          const SizedBox(height: 27),
        ],
        if (userMessages.isEmpty) ...[
          ChatMessageBlock(
            author: 'You',
            assistant: false,
            body: session.task.prompt,
          ),
          const SizedBox(height: 27),
        ],
        _WorkSummaryLine(task: session.task, eventCount: session.events.length),
        const SizedBox(height: 18),
        if (pendingApprovals.isNotEmpty) ...[
          _ApprovalBanner(
            approval: pendingApprovals.first,
            resolving: session.isResolvingApproval,
            onApprove: () => onApprove(pendingApprovals.first.id),
            onReject: () => onReject(pendingApprovals.first.id),
          ),
          const SizedBox(height: 18),
        ],
        if (!session.task.status.isTerminal) ...[
          _WorkerStateCard(task: session.task, onRefresh: onRefresh),
          const SizedBox(height: 18),
        ],
        for (final message in assistantMessages) ...[
          ChatMessageBlock(
            author: 'Phodex',
            assistant: true,
            body: message.content,
          ),
          const SizedBox(height: 27),
        ],
        if (completedResponse != null) ...[
          ChatMessageBlock(
            author: 'Phodex',
            assistant: true,
            body: completedResponse,
          ),
          const SizedBox(height: 27),
        ],
        if (session.task.status.isTerminal &&
            session.task.status != TaskStatus.completed) ...[
          _TaskResultCard(task: session.task, eventResult: eventResult),
          const SizedBox(height: 18),
        ],
        if (session.issues.isNotEmpty) ...[
          for (final issue in session.issues)
            _EventCard(
              title: issue.code ?? issue.type,
              body: issue.message,
              color: const Color(0xFFFF3B30),
            ),
        ],
        _ActivityLogDropdown(
          events: session.events,
          emptyMessage: _emptyActivityMessage(session.task.status),
        ),
      ],
    );
  }

  String _emptyActivityMessage(TaskStatus status) {
    return switch (status) {
      TaskStatus.queued => 'Waiting for the backend worker to pick this up',
      TaskStatus.starting => 'Starting the Codex worker',
      TaskStatus.running => 'Listening for live worker updates',
      TaskStatus.waitingApproval => 'Waiting for your approval',
      TaskStatus.completed => 'No activity was recorded for this task',
      TaskStatus.failed => 'No failure details were recorded',
      TaskStatus.cancelled => 'No cancellation details were recorded',
    };
  }

  String? _latestAgentMessage(List<TaskEventEnvelope> events) {
    for (final event in events.reversed) {
      final item = event.data['item'];
      if (item is Map && item['type'] == 'agent_message') {
        final text = item['text'];
        if (text is String && text.trim().isNotEmpty) {
          return text.trim();
        }
      }

      if (event.data['type'] == 'agent_message') {
        final text = event.data['text'] ?? event.data['message'];
        if (text is String && text.trim().isNotEmpty) {
          return text.trim();
        }
      }
    }
    return null;
  }

  String? _completedResponse({
    required TaskSummary task,
    required String? eventResult,
    required List<TaskMessage> assistantMessages,
  }) {
    if (task.status != TaskStatus.completed) {
      return null;
    }

    final existingBodies = assistantMessages
        .map((message) => message.content.trim())
        .where((content) => content.isNotEmpty)
        .toSet();
    if (eventResult != null && !existingBodies.contains(eventResult)) {
      return eventResult;
    }

    final summary = task.finalSummary?.trim();
    if (summary == null ||
        summary.isEmpty ||
        summary == 'Codex worker completed successfully.' ||
        existingBodies.contains(summary)) {
      return null;
    }
    return summary;
  }
}

class _WorkSummaryLine extends StatelessWidget {
  const _WorkSummaryLine({required this.task, required this.eventCount});

  final TaskSummary task;
  final int eventCount;

  @override
  Widget build(BuildContext context) {
    final label = switch (task.status) {
      TaskStatus.completed => 'Worked for ${_durationLabel()}',
      TaskStatus.failed => 'Stopped after ${_durationLabel()}',
      TaskStatus.cancelled => 'Cancelled after ${_durationLabel()}',
      TaskStatus.waitingApproval => 'Waiting for approval',
      TaskStatus.running => 'Working',
      TaskStatus.starting => 'Starting',
      TaskStatus.queued => 'Queued',
    };

    return Row(
      children: [
        Expanded(child: Divider(height: 1, color: TemplateColors.separator)),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            color: TemplateColors.labelSecondary,
            fontSize: 15,
            height: 20 / 15,
          ),
        ),
        if (eventCount > 0) ...const [
          SizedBox(width: 4),
          Icon(
            Icons.chevron_right_rounded,
            color: TemplateColors.labelSecondary,
            size: 18,
          ),
        ],
        const SizedBox(width: 12),
        Expanded(child: Divider(height: 1, color: TemplateColors.separator)),
      ],
    );
  }

  String _durationLabel() {
    final end = task.finishedAt ?? DateTime.now().toUtc();
    final start = task.startedAt ?? task.createdAt;
    final elapsed = end.difference(start);
    if (elapsed.inHours > 0) {
      final minutes = elapsed.inMinutes.remainder(60);
      return '${elapsed.inHours}h ${minutes}m';
    }
    if (elapsed.inMinutes > 0) {
      final seconds = elapsed.inSeconds.remainder(60);
      return '${elapsed.inMinutes}m ${seconds}s';
    }
    return '${elapsed.inSeconds}s';
  }
}

class _ActivityLogDropdown extends StatefulWidget {
  const _ActivityLogDropdown({
    required this.events,
    required this.emptyMessage,
  });

  final List<TaskEventEnvelope> events;
  final String emptyMessage;

  @override
  State<_ActivityLogDropdown> createState() => _ActivityLogDropdownState();
}

class _ActivityLogDropdownState extends State<_ActivityLogDropdown> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final visibleEvents = widget.events.take(8).toList().reversed.toList();
    final eventCount = widget.events.length;
    final countLabel = eventCount == 1 ? '1 entry' : '$eventCount entries';

    return Container(
      key: const Key('activity-log-dropdown'),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TemplateColors.separator),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Activity',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 17,
                        height: 22 / 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    countLabel,
                    style: const TextStyle(
                      color: TemplateColors.labelSecondary,
                      fontSize: 13,
                      height: 18 / 13,
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 160),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: TemplateColors.labelSecondary,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child: _expanded
                ? Padding(
                    key: const Key('activity-log-entries'),
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Column(
                      children: [
                        if (visibleEvents.isEmpty)
                          _EventCard(
                            title: 'waiting',
                            body: widget.emptyMessage,
                            color: TemplateColors.labelSecondary,
                          )
                        else
                          for (final event in visibleEvents)
                            _EventCard(
                              title: event.type,
                              body: _activityBody(event),
                              color: TemplateColors.labelSecondary,
                            ),
                      ],
                    ),
                  )
                : const SizedBox(
                    key: Key('activity-log-collapsed'),
                    width: double.infinity,
                  ),
          ),
        ],
      ),
    );
  }

  String _activityBody(TaskEventEnvelope event) {
    return event.data['message'] as String? ??
        event.data['summary'] as String? ??
        event.sequence.toString();
  }
}

class _TaskResultCard extends StatelessWidget {
  const _TaskResultCard({required this.task, this.eventResult});

  final TaskSummary task;
  final String? eventResult;

  @override
  Widget build(BuildContext context) {
    final isFailure = task.status == TaskStatus.failed;
    final title = switch (task.status) {
      TaskStatus.completed => 'Result',
      TaskStatus.cancelled => 'Cancelled',
      TaskStatus.failed => 'Failed',
      _ => 'Status',
    };
    final summary = task.finalSummary?.trim();
    final genericSuccess = summary == 'Codex worker completed successfully.';
    final body =
        eventResult ??
        (genericSuccess ? null : summary) ??
        task.errorMessage ??
        switch (task.status) {
          TaskStatus.completed =>
            'The worker completed, but did not return a final summary.',
          TaskStatus.cancelled =>
            'This task was cancelled before a final result was produced.',
          TaskStatus.failed =>
            'The task failed without a detailed error message.',
          _ => task.status.value,
        };

    return Container(
      key: const Key('task-result-card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isFailure ? const Color(0xFFFFF1F0) : const Color(0xFFEFFCF7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFailure ? const Color(0xFFFFD6D2) : const Color(0xFFB8EBD8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isFailure
                  ? const Color(0xFFC5291F)
                  : const Color(0xFF087A55),
              fontSize: 17,
              height: 22 / 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 15,
              height: 21 / 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkerStateCard extends StatelessWidget {
  const _WorkerStateCard({required this.task, required this.onRefresh});

  final TaskSummary task;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final copy = switch (task.status) {
      TaskStatus.queued => (
        title: 'Queued',
        body: 'Your task was created. Waiting for the laptop Codex worker.',
        icon: Icons.hourglass_empty_rounded,
      ),
      TaskStatus.starting => (
        title: 'Starting',
        body: 'The backend accepted the task and is preparing the worker.',
        icon: Icons.autorenew_rounded,
      ),
      TaskStatus.running => (
        title: 'Working',
        body: 'Codex is running. Live updates will appear here as they arrive.',
        icon: Icons.terminal_rounded,
      ),
      TaskStatus.waitingApproval => (
        title: 'Approval needed',
        body: 'Review the request below to let the worker continue.',
        icon: Icons.verified_user_outlined,
      ),
      TaskStatus.completed => (
        title: 'Completed',
        body: 'The task is finished.',
        icon: Icons.check_rounded,
      ),
      TaskStatus.failed => (
        title: 'Failed',
        body: task.errorMessage ?? 'The worker reported a failure.',
        icon: Icons.error_outline_rounded,
      ),
      TaskStatus.cancelled => (
        title: 'Cancelled',
        body: 'This task was cancelled.',
        icon: Icons.close_rounded,
      ),
    };

    return Container(
      key: const Key('worker-state-card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(copy.icon, color: Colors.white, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  copy.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    height: 22 / 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _phaseAwareBody(copy.body),
                  style: const TextStyle(
                    color: Color(0xFFE5E5EA),
                    fontSize: 14,
                    height: 19 / 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onRefresh,
            child: const Icon(Icons.refresh_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  String _phaseAwareBody(String fallback) {
    final phase = task.currentPhase;
    if (phase == null || phase.isEmpty || phase == task.status.value) {
      return fallback;
    }
    return '$fallback Phase: $phase.';
  }
}

class _ApprovalBanner extends StatelessWidget {
  const _ApprovalBanner({
    required this.approval,
    required this.resolving,
    required this.onApprove,
    required this.onReject,
  });

  final ApprovalRequest approval;
  final bool resolving;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('sticky-approval-bar'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            approval.title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 17,
              height: 22 / 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            approval.description,
            style: const TextStyle(
              color: TemplateColors.labelSecondary,
              fontSize: 15,
              height: 20 / 15,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SmallActionButton(
                  title: resolving ? 'Working...' : 'Approve',
                  filled: true,
                  onTap: resolving ? null : onApprove,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SmallActionButton(
                  title: 'Reject',
                  onTap: resolving ? null : onReject,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.title,
    required this.body,
    required this.color,
  });

  final String title;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TemplateColors.promptBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$title: $body',
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: color, fontSize: 13, height: 18 / 13),
      ),
    );
  }
}

class _ReplyComposer extends StatelessWidget {
  const _ReplyComposer({
    required this.controller,
    required this.session,
    required this.onSend,
    required this.onCancel,
    required this.onRepos,
    required this.onApprovals,
  });

  final TextEditingController controller;
  final SessionUiState? session;
  final VoidCallback onSend;
  final VoidCallback onCancel;
  final VoidCallback onRepos;
  final VoidCallback onApprovals;

  @override
  Widget build(BuildContext context) {
    final canSend = session != null && !session!.isSendingReply;
    final canCancel = session != null && !session!.task.status.isTerminal;

    return Row(
      children: [
        TemplateIcon(icon: Icons.folder_outlined, onTap: onRepos),
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            height: 38,
            padding: const EdgeInsets.only(left: 14, right: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: TemplateColors.separator),
              borderRadius: BorderRadius.circular(32),
            ),
            child: TextField(
              key: const Key('session-reply-field'),
              controller: controller,
              enabled: canSend,
              onSubmitted: (_) => onSend(),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Message',
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        TemplateIcon(
          icon: canSend ? Icons.arrow_upward_rounded : Icons.hourglass_empty,
          onTap: canSend ? onSend : null,
        ),
        const SizedBox(width: 12),
        TemplateIcon(
          icon: Icons.close_rounded,
          onTap: canCancel ? onCancel : null,
        ),
        const SizedBox(width: 12),
        TemplateIcon(icon: Icons.headphones_rounded, onTap: onApprovals),
      ],
    );
  }
}

class _SmallActionButton extends StatelessWidget {
  const _SmallActionButton({
    required this.title,
    this.filled = false,
    this.onTap,
  });

  final String title;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: filled ? null : Border.all(color: TemplateColors.separator),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: filled ? Colors.white : Colors.black,
            fontSize: 15,
            height: 20 / 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _SessionError extends StatelessWidget {
  const _SessionError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
      ),
    );
  }
}

class _FrostedTopBar extends StatelessWidget {
  const _FrostedTopBar({
    required this.onOpenRecents,
    required this.onOpenHome,
    required this.onOpenAccount,
  });

  final VoidCallback onOpenRecents;
  final VoidCallback onOpenHome;
  final VoidCallback onOpenAccount;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        border: const Border(
          bottom: BorderSide(color: TemplateColors.separator, width: 0.4),
        ),
      ),
      child: Column(
        children: [
          const TemplateStatusBar(),
          TemplateNavBar(
            onLeadingTap: onOpenRecents,
            onTitleTap: onOpenAccount,
            onTrailingTap: onOpenHome,
          ),
        ],
      ),
    );
  }
}
