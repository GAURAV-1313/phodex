import 'auth_models.dart';

class AccountSummary {
  const AccountSummary({
    required this.user,
    required this.activeSessions,
    required this.deviceOnline,
    required this.deviceLastSeenAt,
    required this.generatedAt,
  });

  final UserProfile user;
  final int activeSessions;
  final bool deviceOnline;
  final DateTime? deviceLastSeenAt;
  final DateTime generatedAt;
}

class UsageSummary {
  const UsageSummary({
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
}

class LimitStatus {
  const LimitStatus({
    required this.generatedAt,
    required this.activeSessions,
    required this.currentConcurrentTasks,
    this.maxActiveSessions,
    this.remainingActiveSessions,
    this.maxConcurrentTasks,
    this.remainingConcurrentTasks,
  });

  final DateTime generatedAt;
  final int? maxActiveSessions;
  final int activeSessions;
  final int? remainingActiveSessions;
  final int? maxConcurrentTasks;
  final int currentConcurrentTasks;
  final int? remainingConcurrentTasks;
}
