import 'package:mobile/core/domain/models/models.dart';

class GitOperationOutDto {
  const GitOperationOutDto({
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

  factory GitOperationOutDto.fromJson(Map<String, dynamic> json) {
    return GitOperationOutDto(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      repoPath: json['repo_path'] as String,
      commitMessage: json['commit_message'] as String,
      status: GitOperationStatusX.fromValue(json['status'] as String),
      statusOutput: json['status_output'] as String?,
      diffStatOutput: json['diff_stat_output'] as String?,
      pushedBranch: json['pushed_branch'] as String?,
      errorMessage: json['error_message'] as String?,
    );
  }

  GitOperation toDomain() {
    return GitOperation(
      id: id,
      taskId: taskId,
      repoPath: repoPath,
      commitMessage: commitMessage,
      status: status,
      statusOutput: statusOutput,
      diffStatOutput: diffStatOutput,
      pushedBranch: pushedBranch,
      errorMessage: errorMessage,
    );
  }
}

class AiSettingsStatusResponseDto {
  const AiSettingsStatusResponseDto({
    required this.hasAnthropicKey,
    required this.hasOpenaiKey,
    this.preferredClaudeModel,
    this.preferredCodexModel,
  });

  final bool hasAnthropicKey;
  final bool hasOpenaiKey;
  final String? preferredClaudeModel;
  final String? preferredCodexModel;

  factory AiSettingsStatusResponseDto.fromJson(Map<String, dynamic> json) {
    return AiSettingsStatusResponseDto(
      hasAnthropicKey: json['has_anthropic_key'] as bool? ?? false,
      hasOpenaiKey: json['has_openai_key'] as bool? ?? false,
      preferredClaudeModel: json['preferred_claude_model'] as String?,
      preferredCodexModel: json['preferred_codex_model'] as String?,
    );
  }

  AiSettingsStatus toDomain() {
    return AiSettingsStatus(
      hasAnthropicKey: hasAnthropicKey,
      hasOpenaiKey: hasOpenaiKey,
      preferredClaudeModel: preferredClaudeModel,
      preferredCodexModel: preferredCodexModel,
    );
  }
}
