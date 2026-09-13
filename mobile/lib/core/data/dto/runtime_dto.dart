import 'package:mobile/core/data/dto/common_dto.dart';
import 'package:mobile/core/domain/models/models.dart';

class PublicRuntimeInfoDto {
  const PublicRuntimeInfoDto({
    required this.mode,
    required this.runnerName,
    required this.demoAvailable,
    required this.workerEngine,
  });

  final String mode;
  final String runnerName;
  final bool demoAvailable;
  final String workerEngine;

  factory PublicRuntimeInfoDto.fromJson(Map<String, dynamic> json) {
    return PublicRuntimeInfoDto(
      mode: json['mode'] as String? ?? 'desktop',
      runnerName: json['runner_name'] as String? ?? 'Phodex Cloud',
      demoAvailable: json['demo_available'] as bool? ?? false,
      workerEngine: json['worker_engine'] as String? ?? 'fake',
    );
  }

  PublicRuntimeInfo toDomain() => PublicRuntimeInfo(
    mode: RuntimeModeX.fromValue(mode),
    runnerName: runnerName,
    demoAvailable: demoAvailable,
    workerEngine: workerEngine,
  );
}

class RuntimeInfoDto {
  const RuntimeInfoDto({
    required this.mode,
    required this.runner,
    required this.hasGithubToken,
    required this.demoAvailable,
    required this.workerEngine,
  });

  final String mode;
  final Map<String, dynamic>? runner;
  final bool hasGithubToken;
  final bool demoAvailable;
  final String workerEngine;

  factory RuntimeInfoDto.fromJson(Map<String, dynamic> json) {
    return RuntimeInfoDto(
      mode: json['mode'] as String? ?? 'desktop',
      runner: json['runner'] as Map<String, dynamic>?,
      hasGithubToken: json['has_github_token'] as bool? ?? false,
      demoAvailable: json['demo_available'] as bool? ?? false,
      workerEngine: json['worker_engine'] as String? ?? 'fake',
    );
  }

  RuntimeInfo toDomain() {
    final runnerJson = runner;
    final lastSeen = runnerJson == null
        ? null
        : parseNullableDateTime(runnerJson['last_seen_at']);
    return RuntimeInfo(
      mode: RuntimeModeX.fromValue(mode),
      runnerName: runnerJson?['name'] as String? ?? 'Phodex Cloud',
      runnerOnline: runnerJson != null && runnerJson['status'] == 'online',
      runnerLastSeenAt: lastSeen,
      hasGithubToken: hasGithubToken,
      demoAvailable: demoAvailable,
      workerEngine: workerEngine,
    );
  }
}
