import 'package:mobile/core/domain/models/models.dart';

/// Describes the backend the app is connected to (desktop vs. Phodex Cloud).
abstract class RuntimeRepository {
  /// Signed-in runtime details, including whether the cloud runner is
  /// online and whether a GitHub token is stored for this user.
  Future<RuntimeInfo> getRuntimeInfo();
}
