enum ProjectContextSourceType { localSynced, manual, github }

extension ProjectContextSourceTypeX on ProjectContextSourceType {
  String get value => switch (this) {
    ProjectContextSourceType.localSynced => 'local_synced',
    ProjectContextSourceType.manual => 'manual',
    ProjectContextSourceType.github => 'github',
  };

  static ProjectContextSourceType fromValue(String value) {
    return switch (value) {
      'manual' => ProjectContextSourceType.manual,
      'github' => ProjectContextSourceType.github,
      _ => ProjectContextSourceType.localSynced,
    };
  }
}

class SyncedRepository {
  const SyncedRepository({
    required this.id,
    required this.userId,
    required this.deviceId,
    required this.deviceName,
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
  final String deviceName;
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

  /// A repository cloned by the cloud runtime from GitHub (as opposed to
  /// one found on a paired desktop by the device agent).
  bool get isCloud => metadata['source'] == 'github';

  /// The GitHub URL for cloud repositories, null for desktop ones.
  String? get remoteUrl => metadata['url'] as String?;
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

  bool get isCloud => sourceType == ProjectContextSourceType.github;
}
