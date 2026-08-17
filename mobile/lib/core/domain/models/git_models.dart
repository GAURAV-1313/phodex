enum GitOperationStatus {
  pendingReview,
  approved,
  running,
  completed,
  failed,
  rejected,
}

extension GitOperationStatusX on GitOperationStatus {
  String get value => switch (this) {
    GitOperationStatus.pendingReview => 'pending_review',
    GitOperationStatus.approved => 'approved',
    GitOperationStatus.running => 'running',
    GitOperationStatus.completed => 'completed',
    GitOperationStatus.failed => 'failed',
    GitOperationStatus.rejected => 'rejected',
  };

  static GitOperationStatus fromValue(String value) {
    return switch (value) {
      'approved' => GitOperationStatus.approved,
      'running' => GitOperationStatus.running,
      'completed' => GitOperationStatus.completed,
      'failed' => GitOperationStatus.failed,
      'rejected' => GitOperationStatus.rejected,
      _ => GitOperationStatus.pendingReview,
    };
  }
}

class GitOperation {
  const GitOperation({
    required this.id,
    required this.taskId,
    required this.repoPath,
    required this.commitMessage,
    required this.status,
    this.statusOutput,
    this.diffStatOutput,
    this.pushedBranch,
    this.errorMessage,
  });

  final String id;
  final String taskId;
  final String repoPath;
  final String commitMessage;
  final GitOperationStatus status;
  final String? statusOutput;
  final String? diffStatOutput;
  final String? pushedBranch;
  final String? errorMessage;

  GitOperation copyWith({
    String? commitMessage,
    GitOperationStatus? status,
    String? errorMessage,
  }) {
    return GitOperation(
      id: id,
      taskId: taskId,
      repoPath: repoPath,
      commitMessage: commitMessage ?? this.commitMessage,
      status: status ?? this.status,
      statusOutput: statusOutput,
      diffStatOutput: diffStatOutput,
      pushedBranch: pushedBranch,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AiSettingsStatus {
  const AiSettingsStatus({
    required this.hasAnthropicKey,
    required this.hasOpenaiKey,
    this.preferredClaudeModel,
    this.preferredCodexModel,
  });

  final bool hasAnthropicKey;
  final bool hasOpenaiKey;
  final String? preferredClaudeModel;
  final String? preferredCodexModel;
}
