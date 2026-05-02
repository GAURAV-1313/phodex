import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/core/session/session_event_ordering.dart';
import 'package:mobile/features/session/application/session_state.dart';

SessionUiState reduceSessionWithEvent(
  SessionUiState current,
  TaskEventEnvelope incoming,
) {
  var task = current.task;

  switch (incoming.type) {
    case 'task.starting':
      task = task.copyWith(
        status: TaskStatus.starting,
        currentPhase: 'booting_worker',
      );
    case 'task.running':
      task = task.copyWith(status: TaskStatus.running, currentPhase: 'running');
    case 'task.completed':
      task = task.copyWith(
        status: TaskStatus.completed,
        currentPhase: 'done',
        finalSummary: incoming.data['summary'] as String?,
        finishedAt: DateTime.now().toUtc(),
      );
    case 'task.failed':
      task = task.copyWith(
        status: TaskStatus.failed,
        currentPhase: 'failed',
        errorMessage: incoming.data['message'] as String?,
        finishedAt: DateTime.now().toUtc(),
      );
    case 'task.cancelled':
      task = task.copyWith(
        status: TaskStatus.cancelled,
        currentPhase: 'cancelled',
        finishedAt: DateTime.now().toUtc(),
      );
    case 'approval.requested':
      task = task.copyWith(
        status: TaskStatus.waitingApproval,
        currentPhase: 'awaiting_user_approval',
      );
    default:
      task = task;
  }

  final mergedEvents = mergeOrderedEvents(current.events, <TaskEventEnvelope>[
    incoming,
  ]);

  final approvalId = incoming.data['approval_id'] as String?;
  final approvals = [...current.approvals];
  if (incoming.type == 'approval.requested' && approvalId != null) {
    final exists = approvals.any((approval) => approval.id == approvalId);
    if (!exists) {
      approvals.add(
        ApprovalRequest(
          id: approvalId,
          taskId: current.task.id,
          kind: 'command_execution',
          title: incoming.data['title'] as String? ?? 'Approval required',
          description:
              incoming.data['description'] as String? ??
              'User approval required',
          payload: incoming.data,
          status: ApprovalStatus.pending,
          createdAt: incoming.timestamp,
          resolvedAt: null,
        ),
      );
    }
  }

  if ((incoming.type == 'approval.approved' ||
          incoming.type == 'approval.rejected') &&
      approvalId != null) {
    for (var index = 0; index < approvals.length; index += 1) {
      if (approvals[index].id == approvalId) {
        approvals[index] = approvals[index].copyWith(
          status: incoming.type == 'approval.approved'
              ? ApprovalStatus.approved
              : ApprovalStatus.rejected,
          resolvedAt: incoming.timestamp,
        );
      }
    }
  }

  final issues = [...current.issues];
  final errorCode = incoming.data['error_code'] as String?;
  if (incoming.type == 'task.failed' || incoming.type == 'approval.rejected') {
    issues.add(
      TaskIssue(
        sequence: incoming.sequence,
        type: incoming.type,
        timestamp: incoming.timestamp,
        code: errorCode,
        message: incoming.data['message'] as String? ?? incoming.type,
        data: incoming.data,
      ),
    );
  }

  return current.copyWith(
    task: task,
    events: mergedEvents,
    approvals: approvals,
    issues: issues,
  );
}
