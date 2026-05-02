import 'package:mobile/core/data/dto/common_dto.dart';
import 'package:mobile/core/domain/models/models.dart';

class UsageSummaryResponseDto {
  const UsageSummaryResponseDto({
    required this.userId,
    required this.generatedAt,
    required this.totalTasks,
    required this.queuedTasks,
    required this.runningTasks,
    required this.waitingApprovalTasks,
    required this.completedTasks,
    required this.failedTasks,
    required this.cancelledTasks,
    required this.pendingApprovals,
    required this.totalEvents,
    required this.activeSessions,
  });

  final String userId;
  final DateTime generatedAt;
  final int totalTasks;
  final int queuedTasks;
  final int runningTasks;
  final int waitingApprovalTasks;
  final int completedTasks;
  final int failedTasks;
  final int cancelledTasks;
  final int pendingApprovals;
  final int totalEvents;
  final int activeSessions;

  factory UsageSummaryResponseDto.fromJson(Map<String, dynamic> json) {
    return UsageSummaryResponseDto(
      userId: json['user_id'] as String,
      generatedAt: parseDateTime(json['generated_at']),
      totalTasks: json['total_tasks'] as int,
      queuedTasks: json['queued_tasks'] as int,
      runningTasks: json['running_tasks'] as int,
      waitingApprovalTasks: json['waiting_approval_tasks'] as int,
      completedTasks: json['completed_tasks'] as int,
      failedTasks: json['failed_tasks'] as int,
      cancelledTasks: json['cancelled_tasks'] as int,
      pendingApprovals: json['pending_approvals'] as int,
      totalEvents: json['total_events'] as int,
      activeSessions: json['active_sessions'] as int,
    );
  }

  UsageSummary toDomain() {
    return UsageSummary(
      userId: userId,
      generatedAt: generatedAt,
      totalTasks: totalTasks,
      queuedTasks: queuedTasks,
      runningTasks: runningTasks,
      waitingApprovalTasks: waitingApprovalTasks,
      completedTasks: completedTasks,
      failedTasks: failedTasks,
      cancelledTasks: cancelledTasks,
      pendingApprovals: pendingApprovals,
      totalEvents: totalEvents,
      activeSessions: activeSessions,
    );
  }
}

class LimitStatusResponseDto {
  const LimitStatusResponseDto({
    required this.generatedAt,
    required this.maxActiveSessions,
    required this.activeSessions,
    required this.remainingActiveSessions,
    required this.maxConcurrentTasks,
    required this.currentConcurrentTasks,
    required this.remainingConcurrentTasks,
  });

  final DateTime generatedAt;
  final int? maxActiveSessions;
  final int activeSessions;
  final int? remainingActiveSessions;
  final int? maxConcurrentTasks;
  final int currentConcurrentTasks;
  final int? remainingConcurrentTasks;

  factory LimitStatusResponseDto.fromJson(Map<String, dynamic> json) {
    return LimitStatusResponseDto(
      generatedAt: parseDateTime(json['generated_at']),
      maxActiveSessions: json['max_active_sessions'] as int?,
      activeSessions: json['active_sessions'] as int,
      remainingActiveSessions: json['remaining_active_sessions'] as int?,
      maxConcurrentTasks: json['max_concurrent_tasks'] as int?,
      currentConcurrentTasks: json['current_concurrent_tasks'] as int,
      remainingConcurrentTasks: json['remaining_concurrent_tasks'] as int?,
    );
  }

  LimitStatus toDomain() {
    return LimitStatus(
      generatedAt: generatedAt,
      maxActiveSessions: maxActiveSessions,
      activeSessions: activeSessions,
      remainingActiveSessions: remainingActiveSessions,
      maxConcurrentTasks: maxConcurrentTasks,
      currentConcurrentTasks: currentConcurrentTasks,
      remainingConcurrentTasks: remainingConcurrentTasks,
    );
  }
}
