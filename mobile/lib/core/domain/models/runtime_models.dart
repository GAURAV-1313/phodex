/// Which kind of backend the app is talking to.
///
/// - [desktop]: the backend runs on the user's own laptop (paired via QR);
///   tasks execute against repositories on that machine.
/// - [cloud]: a hosted "Phodex Cloud" backend that clones GitHub
///   repositories and runs tasks itself, with no laptop involved.
enum RuntimeMode { desktop, cloud }

extension RuntimeModeX on RuntimeMode {
  String get value => switch (this) {
    RuntimeMode.desktop => 'desktop',
    RuntimeMode.cloud => 'cloud',
  };

  static RuntimeMode fromValue(String? value) =>
      value == 'cloud' ? RuntimeMode.cloud : RuntimeMode.desktop;
}

/// What a backend says about itself before sign-in (`GET /runtime/public`).
class PublicRuntimeInfo {
  const PublicRuntimeInfo({
    required this.mode,
    required this.runnerName,
    required this.demoAvailable,
    required this.workerEngine,
  });

  final RuntimeMode mode;
  final String runnerName;

  /// The server exposes a public demo account (`POST /auth/demo`).
  final bool demoAvailable;
  final String workerEngine;

  bool get isCloud => mode == RuntimeMode.cloud;
}

/// The signed-in view of the runtime (`GET /runtime`).
class RuntimeInfo {
  const RuntimeInfo({
    required this.mode,
    required this.runnerName,
    required this.runnerOnline,
    required this.runnerLastSeenAt,
    required this.hasGithubToken,
    required this.demoAvailable,
    required this.workerEngine,
  });

  final RuntimeMode mode;
  final String runnerName;
  final bool runnerOnline;
  final DateTime? runnerLastSeenAt;
  final bool hasGithubToken;
  final bool demoAvailable;
  final String workerEngine;

  bool get isCloud => mode == RuntimeMode.cloud;
}
