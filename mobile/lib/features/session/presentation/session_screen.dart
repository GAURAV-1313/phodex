import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/core/providers/repository_providers.dart';
import 'package:mobile/features/repos/application/repos_controller.dart';
import 'package:mobile/features/session/application/session_controller.dart';
import 'package:mobile/features/session/application/session_state.dart';
import 'package:mobile/shared/theme/theme.dart';
import 'package:mobile/shared/widgets/issue_card.dart';
import 'package:mobile/shared/widgets/phodex_mascot.dart';
import 'package:mobile/shared/widgets/stagger_in.dart';
import 'package:mobile/shared/widgets/stitch_nav.dart';
import 'package:mobile/shared/widgets/stitch_ui.dart';
import 'package:mobile/shared/widgets/trace_card.dart';

/// Bottom inset for the scrollable content so the last card clears the
/// pinned composer.
const double _composerClearance = stitchDockClearance + AppSpacing.s24;

class SessionScreen extends ConsumerWidget {
  const SessionScreen({super.key, required this.taskId});
  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(sessionProvider(taskId));
    final session = value.asData?.value;
    final selected = ref.watch(selectedProjectContextProvider).asData?.value;
    final repos =
        ref.watch(repositoriesProvider).asData?.value ??
        const <SyncedRepository>[];

    // Only show a context pill when we can genuinely attribute the task to
    // the currently selected context — never a guessed one.
    ({String name, String? branch})? projectContext;
    if (session != null &&
        selected != null &&
        session.task.projectContextId != null &&
        selected.id == session.task.projectContextId) {
      projectContext = describeProjectContext(selected, repos);
    }

    final notifier = ref.read(sessionProvider(taskId).notifier);
    final title = session?.task.title ?? session?.task.prompt ?? 'Task';
    final showComposer = session != null && !session.task.status.isTerminal;

    return StitchScaffold(
      showDock: false,
      bottom: showComposer
          ? _SessionComposer(
              session: session,
              onSend: (message) => _sendReply(context, notifier, message),
              onStop: () => _confirmStop(context, notifier),
            )
          : null,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.screenTop,
              AppSpacing.screen,
              0,
            ),
            child: StitchHeader(
              title: title,
              onBack: () => stitchPopOrGo(context, '/activity'),
              trailing: session == null
                  ? null
                  : IconButton(
                      tooltip: 'Execution logs',
                      onPressed: () => _showLogs(context, session, notifier),
                      icon: const Icon(Icons.terminal_rounded),
                    ),
            ),
          ),
          Expanded(
            // Not StitchAsyncView: its loading branch is the mascot spinner,
            // and this screen wants layout-shaped skeleton blocks instead.
            child: session != null
                ? _ExecutionView(
                    session: session,
                    projectContext: projectContext,
                    onApprove: notifier.approve,
                    onReject: (id, {note}) => notifier.reject(id, note: note),
                    onShowLogs: () => _showLogs(context, session, notifier),
                    onResume: notifier.resumeTask,
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
                        .discardCommit(
                          taskId: taskId,
                          gitOperationId: gitOperationId,
                        ),
                    onContinueWithNewTask: notifier.continueWithNewTask,
                  )
                : value.hasError
                ? StitchErrorState(
                    title: "Couldn't load this task",
                    onRetry: () => ref.invalidate(sessionProvider(taskId)),
                  )
                : const _SessionSkeleton(),
          ),
        ],
      ),
    );
  }

  Future<void> _sendReply(
    BuildContext context,
    SessionController notifier,
    String message,
  ) async {
    try {
      await notifier.sendReply(message);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Couldn't send your reply"),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => _sendReply(context, notifier, message),
          ),
        ),
      );
    }
  }

  Future<void> _confirmStop(
    BuildContext context,
    SessionController notifier,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Stop this task?'),
        content: const Text(
          'The agent will stop where it is. Anything it already changed stays '
          'in your working tree.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep running'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Stop task'),
          ),
        ],
      ),
    );
    if (confirmed == true) await notifier.cancelTask();
  }

  void _showLogs(
    BuildContext context,
    SessionUiState session,
    SessionController notifier,
  ) {
    showStitchSheet<void>(
      context,
      title: 'Execution logs',
      child: _LogsSheet(
        events: session.events,
        onForceTerminate: session.task.status.isTerminal
            ? null
            : notifier.cancelTask,
      ),
    );
  }
}

/// The pinned reply bar. Owns its text controller so typing survives the
/// stream of session rebuilds.
class _SessionComposer extends StatefulWidget {
  const _SessionComposer({
    required this.session,
    required this.onSend,
    required this.onStop,
  });

  final SessionUiState session;
  final ValueChanged<String> onSend;
  final VoidCallback onStop;

  @override
  State<_SessionComposer> createState() => _SessionComposerState();
}

class _SessionComposerState extends State<_SessionComposer> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final message = _controller.text.trim();
    if (message.isEmpty) return;
    widget.onSend(message);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.s16,
      AppSpacing.s8,
      AppSpacing.s16,
      AppSpacing.s12,
    ),
    child: ComposerBar(
      controller: _controller,
      hint: 'Reply to this task…',
      onSend: _send,
      sending: widget.session.isSendingReply,
      running: widget.session.isExecuting,
      onStop: widget.onStop,
    ),
  );
}

class _ExecutionView extends StatefulWidget {
  const _ExecutionView({
    required this.session,
    required this.projectContext,
    required this.onApprove,
    required this.onReject,
    required this.onShowLogs,
    required this.onResume,
    required this.onPrepareCommit,
    required this.onConfirmCommit,
    required this.onDiscardCommit,
    required this.onContinueWithNewTask,
  });

  final SessionUiState session;
  final ({String name, String? branch})? projectContext;
  final Future<void> Function(String approvalId) onApprove;
  final Future<void> Function(String approvalId, {String? note}) onReject;
  final VoidCallback onShowLogs;
  final Future<void> Function() onResume;
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
  bool _preparingCommit = false;
  bool _resuming = false;
  bool _showAllSteps = false;

  static const int _visibleSteps = 6;

  Future<void> _resolveApproval(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Couldn't resolve this approval"),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => _resolveApproval(action),
          ),
        ),
      );
    }
  }

  Future<void> _startCommitFlow() async {
    setState(() => _preparingCommit = true);
    GitOperation operation;
    try {
      operation = await widget.onPrepareCommit();
    } catch (_) {
      if (!mounted) return;
      setState(() => _preparingCommit = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Couldn't prepare the commit"),
          action: SnackBarAction(label: 'Retry', onPressed: _startCommitFlow),
        ),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _preparingCommit = false);

    await showStitchSheet<void>(
      context,
      child: _CommitPushSheet(
        operation: operation,
        onConfirm: widget.onConfirmCommit,
        onDiscard: widget.onDiscardCommit,
      ),
    );
  }

  Future<void> _resume() async {
    setState(() => _resuming = true);
    try {
      await widget.onResume();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't resume the task")),
      );
    } finally {
      if (mounted) setState(() => _resuming = false);
    }
  }

  Future<void> _startFollowUpTask() async {
    final newTaskId = await showStitchSheet<String>(
      context,
      title: 'Start a follow-up task',
      child: _FollowUpTaskSheet(
        projectContext: widget.projectContext,
        onSubmit: widget.onContinueWithNewTask,
      ),
    );
    if (newTaskId != null && mounted) {
      // Replace rather than stack sessions so "back" from the new task
      // still returns to where the user came from originally.
      context.pushReplacement('/session/$newTaskId');
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final task = session.task;
    ApprovalRequest? approval;
    for (final item in session.approvals) {
      if (item.status == ApprovalStatus.pending) {
        approval = item;
        break;
      }
    }
    final complete = task.status.isTerminal;

    // The worker's phase ("booting worker", "analyzing context") adds detail
    // beyond the status chip — but only while live, and only when it says
    // something the chip doesn't already.
    final phaseLabel = task.currentPhase == null
        ? null
        : traceTypeLabel(task.currentPhase!);
    final showPhase =
        !complete &&
        phaseLabel != null &&
        phaseLabel.toLowerCase() !=
            taskStatusLabel(task.status.value).toLowerCase();

    // Raw per-line log output belongs in the logs sheet, not the milestone
    // trace — otherwise a verbose git push floods the timeline.
    final steps = session.events
        .where((event) => event.type != 'task.log' && event.type != 'git.log')
        .toList();
    final hidden = _showAllSteps
        ? 0
        : (steps.length - _visibleSteps).clamp(0, steps.length);
    final visibleSteps = steps.sublist(hidden);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.s16,
        AppSpacing.screen,
        complete ? AppSpacing.s32 : _composerClearance,
      ),
      children: [
        Wrap(
          spacing: AppSpacing.s8,
          runSpacing: AppSpacing.s8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TaskStatusChip(
              status: task.status.value,
              pulse: session.isExecuting,
            ),
            if (widget.projectContext case final projectContext?)
              ContextPill(
                name: projectContext.name,
                branch: projectContext.branch,
              ),
          ],
        ),
        if (session.isReconnecting) ...[
          const SizedBox(height: AppSpacing.s12),
          const StatusBanner(
            tone: StatusTone.warning,
            busy: true,
            message: 'Reconnecting to live updates…',
          ),
        ],
        if (task.status == TaskStatus.failed ||
            task.status == TaskStatus.cancelled) ...[
          const SizedBox(height: AppSpacing.s12),
          StatusBanner(
            tone: StatusTone.warning,
            busy: _resuming,
            message: task.currentPhase == 'interrupted'
                ? 'Phodex stopped while this task was running. Its changes are '
                      'still in your working tree.'
                : 'This task stopped before it finished. Resume to let the '
                      'agent pick up where it left off.',
            actionLabel: _resuming ? null : 'Resume',
            onAction: _resuming ? null : _resume,
          ),
        ],
        const SizedBox(height: AppSpacing.s16),
        Text(
          task.prompt,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: context.text.bodyMedium,
        ),
        if (showPhase) ...[
          const SizedBox(height: AppSpacing.s4),
          Text(phaseLabel, style: context.text.labelMedium),
        ],
        const SizedBox(height: AppSpacing.s24),
        StitchSectionLabel(
          'Execution trace',
          trailing: TextButton.icon(
            onPressed: widget.onShowLogs,
            icon: const Icon(Icons.terminal_rounded, size: 18),
            label: const Text('Logs'),
          ),
        ),
        if (steps.isEmpty)
          Text(
            complete
                ? 'No steps were recorded for this task.'
                : 'Waiting for the first step…',
            style: context.text.bodySmall,
          ),
        if (hidden > 0)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => setState(() => _showAllSteps = true),
              child: Text('Show $hidden earlier steps'),
            ),
          ),
        for (final (i, event) in visibleSteps.indexed)
          StaggerIn(
            key: ValueKey(event.eventId),
            index: i,
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s8),
              child: TraceCard(event: event),
            ),
          ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) => SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, .25),
              end: Offset.zero,
            ).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: approval == null
              ? const SizedBox.shrink()
              : Padding(
                  key: ValueKey(approval.id),
                  padding: const EdgeInsets.only(top: AppSpacing.s16),
                  child: _ApprovalBlock(
                    approval: approval,
                    busy: session.isResolvingApproval,
                    onApprove: () =>
                        _resolveApproval(() => widget.onApprove(approval!.id)),
                    onReject: () async {
                      final reason = await showRejectReasonDialog(context);
                      if (reason == null) return;
                      await _resolveApproval(
                        () => widget.onReject(
                          approval!.id,
                          note: reason.isEmpty ? null : reason,
                        ),
                      );
                    },
                  ),
                ),
        ),
        if (complete) ...[
          const SizedBox(height: AppSpacing.s16),
          _CompletionCard(task: task, messages: session.messages),
          if (session.issues.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s16),
            for (final issue in session.issues) IssueCard(issue: issue),
          ],
          const SizedBox(height: AppSpacing.s24),
          if (task.status == TaskStatus.completed) ...[
            StitchSecondaryButton(
              label: _preparingCommit
                  ? 'Checking for changes…'
                  : 'Commit & Push',
              icon: Icons.upload_rounded,
              onPressed: _preparingCommit ? null : _startCommitFlow,
            ),
            const SizedBox(height: AppSpacing.s12),
          ],
          StitchPrimaryButton(
            label: 'Done',
            onPressed: () => stitchPopOrGo(context, '/activity'),
          ),
          const SizedBox(height: AppSpacing.s8),
          TextButton(
            onPressed: _startFollowUpTask,
            child: const Text('Start a follow-up task'),
          ),
        ],
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
    final colors = context.colors;
    final command = approval.payload['command']?.toString() ?? approval.title;
    final workdir = approval.payload['workdir']?.toString();
    final preview = workdir == null
        ? '\$ $command'
        : '\$ $command\n# in $workdir';
    return StitchCard(
      border: Border.all(color: colors.accentWarning.withValues(alpha: .5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.gpp_maybe_outlined,
                size: 18,
                color: colors.accentWarning,
              ),
              const SizedBox(width: AppSpacing.s8),
              Text(
                'HUMAN VERIFICATION NEEDED',
                style: context.text.labelSmall?.copyWith(
                  color: colors.accentWarning,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          Text(approval.title, style: context.text.titleLarge),
          const SizedBox(height: AppSpacing.s8),
          Text(approval.description, style: context.text.bodyMedium),
          const SizedBox(height: AppSpacing.s12),
          StitchTerminalBlock(text: preview, maxLines: 4),
          const SizedBox(height: AppSpacing.s16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: busy ? null : onReject,
                  child: Semantics(
                    label: 'Reject: ${approval.title}',
                    excludeSemantics: true,
                    child: const Text('Reject'),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: FilledButton(
                  onPressed: busy ? null : onApprove,
                  child: Semantics(
                    label: busy
                        ? 'Resolving approval'
                        : 'Approve: ${approval.title}',
                    excludeSemantics: true,
                    child: Text(busy ? 'Resolving…' : 'Approve'),
                  ),
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
    final mood = moodForTaskStatus(task.status);
    return StitchCard(
      child: Column(
        children: [
          PhodexMascot(size: 64, mood: mood),
          const SizedBox(height: AppSpacing.s12),
          Text(
            taskStatusLabel(task.status.value),
            style: context.text.titleMedium?.copyWith(
              color: taskStatusColor(context.colors, task.status.value),
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            summary,
            textAlign: TextAlign.center,
            style: context.text.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// Grey placeholder blocks shaped like the loaded screen (status row,
/// prompt, a few trace cards) so the layout doesn't jump when data lands.
class _SessionSkeleton extends StatelessWidget {
  const _SessionSkeleton();

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Loading task',
    liveRegion: true,
    child: ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.s16,
          AppSpacing.screen,
          AppSpacing.screen,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                _Bone(width: AppSpacing.s48 * 2, height: AppSpacing.s32),
                SizedBox(width: AppSpacing.s8),
                _Bone(width: AppSpacing.s48 * 3, height: AppSpacing.s32),
              ],
            ),
            const SizedBox(height: AppSpacing.s16),
            const _Bone(height: AppSpacing.s20),
            const SizedBox(height: AppSpacing.s8),
            const _Bone(width: AppSpacing.s48 * 4, height: AppSpacing.s20),
            const SizedBox(height: AppSpacing.s32),
            for (var i = 0; i < 4; i++) ...[
              const _Bone(height: AppSpacing.s48 + AppSpacing.s16),
              const SizedBox(height: AppSpacing.s8),
            ],
          ],
        ),
      ),
    ),
  );
}

class _Bone extends StatelessWidget {
  const _Bone({this.width = double.infinity, required this.height});
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: context.colors.bgInput,
      borderRadius: BorderRadius.circular(AppRadii.chip),
    ),
  );
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
  String? _error;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  bool get _resolved =>
      _operation.status == GitOperationStatus.completed ||
      _operation.status == GitOperationStatus.failed;

  Future<void> _confirm() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final resolved = await widget.onConfirm(
        _operation.id,
        _message.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _operation = resolved;
        _busy = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = "Couldn't commit and push. Check the runtime and try again.";
      });
    }
  }

  Future<void> _discard() async {
    setState(() => _busy = true);
    try {
      await widget.onDiscard(_operation.id);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (_resolved) {
      final ok = _operation.status == GitOperationStatus.completed;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: PhodexMascot(
              size: 64,
              mood: ok ? MascotMood.success : MascotMood.error,
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          Text(
            ok ? 'Pushed to GitHub' : "Couldn't push",
            textAlign: TextAlign.center,
            style: context.text.headlineSmall,
          ),
          if (_operation.errorMessage case final error?) ...[
            const SizedBox(height: AppSpacing.s8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium?.copyWith(
                color: colors.accentError,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.s24),
          StitchPrimaryButton(
            label: 'Close',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Commit & push to GitHub', style: context.text.headlineSmall),
        const SizedBox(height: AppSpacing.s16),
        TextField(
          controller: _message,
          decoration: const InputDecoration(labelText: 'Commit message'),
        ),
        const SizedBox(height: AppSpacing.s16),
        if ((_operation.statusOutput ?? '').isNotEmpty) ...[
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: AppSpacing.s48 * 4),
            child: SingleChildScrollView(
              child: StitchTerminalBlock(
                label: 'Changes',
                text: _operation.statusOutput!,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
        ],
        if (_error case final error?) ...[
          StatusBanner(tone: StatusTone.error, message: error),
          const SizedBox(height: AppSpacing.s16),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _busy ? null : _discard,
                child: const Text('Discard'),
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: FilledButton(
                onPressed: _busy ? null : _confirm,
                child: Text(_busy ? 'Pushing…' : 'Commit & push'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FollowUpTaskSheet extends StatefulWidget {
  const _FollowUpTaskSheet({
    required this.projectContext,
    required this.onSubmit,
  });

  final ({String name, String? branch})? projectContext;
  final Future<TaskSummary?> Function(String prompt) onSubmit;

  @override
  State<_FollowUpTaskSheet> createState() => _FollowUpTaskSheetState();
}

class _FollowUpTaskSheetState extends State<_FollowUpTaskSheet> {
  final _prompt = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _prompt.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final prompt = _prompt.text.trim();
    if (prompt.isEmpty || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final task = await widget.onSubmit(prompt);
      if (!mounted) return;
      if (task != null) {
        Navigator.pop(context, task.id);
      } else {
        setState(() => _submitting = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = "Couldn't start the task. Try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Phodex keeps the same repository and picks up where this task '
        'left off.',
        style: context.text.bodyMedium,
      ),
      const SizedBox(height: AppSpacing.s16),
      if (_error case final error?) ...[
        StatusBanner(tone: StatusTone.error, message: error),
        const SizedBox(height: AppSpacing.s12),
      ],
      ComposerBar(
        controller: _prompt,
        autofocus: true,
        hint: 'Describe what you need built next…',
        sending: _submitting,
        onSend: _submit,
        context: widget.projectContext == null
            ? null
            : ContextPill(
                name: widget.projectContext!.name,
                branch: widget.projectContext!.branch,
              ),
      ),
    ],
  );
}

/// Raw command output and log lines on the terminal surface — the one place
/// the UI is deliberately dark in both themes.
class _LogsSheet extends StatelessWidget {
  const _LogsSheet({required this.events, required this.onForceTerminate});

  final List<TaskEventEnvelope> events;
  final Future<void> Function()? onForceTerminate;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final logs = events
        .where((event) => event.type == 'task.log' || event.type == 'git.log')
        .toList();
    final height = MediaQuery.sizeOf(context).height * .6;
    return SizedBox(
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.s16),
              decoration: BoxDecoration(
                color: colors.terminalBg,
                borderRadius: BorderRadius.circular(AppRadii.button),
              ),
              child: logs.isEmpty
                  ? Text(
                      'No log output yet.',
                      style: AppTypography.code(color: colors.terminalMuted),
                    )
                  : ListView.separated(
                      itemCount: logs.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.s12),
                      itemBuilder: (context, index) =>
                          _LogEntry(event: logs[index]),
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
              if (onForceTerminate case final terminate?) ...[
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      terminate();
                    },
                    child: const Text('Force terminate'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _LogEntry extends StatelessWidget {
  const _LogEntry({required this.event});
  final TaskEventEnvelope event;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final details = TraceDetails.of(event);
    final message = event.data['message']?.toString();
    final lines = <(String, Color)>[
      if (message != null && message.isNotEmpty) (message, colors.terminalText),
      if (details.command != null)
        ('\$ ${details.command}', colors.terminalText),
      if (details.output != null) (details.output!, colors.terminalMuted),
      for (final change in details.fileChanges)
        (
          '${change.action} ${change.path} +${change.added} −${change.removed}',
          colors.terminalMuted,
        ),
    ];
    if (lines.isEmpty) lines.add((event.type, colors.terminalMuted));
    return Semantics(
      label: 'Log: ${event.type}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (text, color) in lines)
            Text(text, style: AppTypography.code(color: color)),
        ],
      ),
    );
  }
}
