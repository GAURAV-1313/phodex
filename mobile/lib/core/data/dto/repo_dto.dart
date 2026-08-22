import 'package:mobile/core/data/dto/common_dto.dart';
import 'package:mobile/core/domain/models/models.dart';

class SyncedRepositoryOutDto {
  const SyncedRepositoryOutDto({
    required this.id,
    required this.userId,
    required this.deviceId,
    required this.deviceName,
    required this.name,
    required this.localPath,
    required this.gitRoot,
    required this.currentBranch,
    required this.defaultBranch,
    required this.isActive,
    required this.lastScannedAt,
    required this.lastOpenedAt,
    required this.metadataJson,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String deviceId;
  final String deviceName;
  final String name;
  final String localPath;
  final String gitRoot;
  final String? currentBranch;
  final String? defaultBranch;
  final bool isActive;
  final DateTime? lastScannedAt;
  final DateTime? lastOpenedAt;
  final Map<String, dynamic> metadataJson;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory SyncedRepositoryOutDto.fromJson(Map<String, dynamic> json) {
    return SyncedRepositoryOutDto(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      deviceId: json['device_id'] as String,
      deviceName: json['device_name'] as String,
      name: json['name'] as String,
      localPath: json['local_path'] as String,
      gitRoot: json['git_root'] as String,
      currentBranch: json['current_branch'] as String?,
      defaultBranch: json['default_branch'] as String?,
      isActive: json['is_active'] as bool,
      lastScannedAt: parseNullableDateTime(json['last_scanned_at']),
      lastOpenedAt: parseNullableDateTime(json['last_opened_at']),
      metadataJson:
          (json['metadata_json'] as Map<String, dynamic>?) ??
          <String, dynamic>{},
      createdAt: parseDateTime(json['created_at']),
      updatedAt: parseDateTime(json['updated_at']),
    );
  }

  SyncedRepository toDomain() {
    return SyncedRepository(
      id: id,
      userId: userId,
      deviceId: deviceId,
      deviceName: deviceName,
      name: name,
      localPath: localPath,
      gitRoot: gitRoot,
      currentBranch: currentBranch,
      defaultBranch: defaultBranch,
      isActive: isActive,
      lastScannedAt: lastScannedAt,
      lastOpenedAt: lastOpenedAt,
      metadata: metadataJson,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class RepoListResponseDto {
  const RepoListResponseDto({required this.items});

  final List<SyncedRepositoryOutDto> items;

  factory RepoListResponseDto.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List<dynamic>? ?? <dynamic>[])
        .cast<Map<String, dynamic>>();
    return RepoListResponseDto(
      items: rawItems.map(SyncedRepositoryOutDto.fromJson).toList(),
    );
  }
}

class ProjectContextOutDto {
  const ProjectContextOutDto({
    required this.id,
    required this.userId,
    required this.sourceType,
    required this.syncedRepositoryId,
    required this.name,
    required this.repoUrl,
    required this.branch,
    required this.metadataJson,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final ProjectContextSourceType sourceType;
  final String? syncedRepositoryId;
  final String name;
  final String? repoUrl;
  final String? branch;
  final Map<String, dynamic> metadataJson;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ProjectContextOutDto.fromJson(Map<String, dynamic> json) {
    return ProjectContextOutDto(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      sourceType: ProjectContextSourceTypeX.fromValue(
        json['source_type'] as String,
      ),
      syncedRepositoryId: json['synced_repository_id'] as String?,
      name: json['name'] as String,
      repoUrl: json['repo_url'] as String?,
      branch: json['branch'] as String?,
      metadataJson:
          (json['metadata_json'] as Map<String, dynamic>?) ??
          <String, dynamic>{},
      createdAt: parseDateTime(json['created_at']),
      updatedAt: parseDateTime(json['updated_at']),
    );
  }

  ProjectContext toDomain() {
    return ProjectContext(
      id: id,
      userId: userId,
      sourceType: sourceType,
      syncedRepositoryId: syncedRepositoryId,
      name: name,
      repoUrl: repoUrl,
      branch: branch,
      metadata: metadataJson,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
