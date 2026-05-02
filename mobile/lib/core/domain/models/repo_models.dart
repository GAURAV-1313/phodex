enum ProjectContextSourceType { localSynced, manual }

extension ProjectContextSourceTypeX on ProjectContextSourceType {
  String get value => switch (this) {
    ProjectContextSourceType.localSynced => 'local_synced',
    ProjectContextSourceType.manual => 'manual',
  };

  static ProjectContextSourceType fromValue(String value) {
    return value == 'manual'
        ? ProjectContextSourceType.manual
        : ProjectContextSourceType.localSynced;
  }
}

class SyncedRepository {
  const SyncedRepository({
    required this.id,
    required this.userId,
    required this.deviceId,
    required this.name,
    required this.localPath,
    required this.gitRoot,
    required this.isActive,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
    this.currentBranch,
    this.defaultBranch,
    this.lastScannedAt,
    this.lastOpenedAt,
  });

  final String id;
  final String userId;
  final String deviceId;
  final String name;
  final String localPath;
  final String gitRoot;
  final String? currentBranch;
  final String? defaultBranch;
  final bool isActive;
  final DateTime? lastScannedAt;
  final DateTime? lastOpenedAt;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class ProjectContext {
  const ProjectContext({
    required this.id,
    required this.userId,
    required this.sourceType,
    required this.name,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
    this.syncedRepositoryId,
    this.repoUrl,
    this.branch,
  });

  final String id;
  final String userId;
  final ProjectContextSourceType sourceType;
  final String? syncedRepositoryId;
  final String name;
  final String? repoUrl;
  final String? branch;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
}
