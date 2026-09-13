import 'package:mobile/core/domain/models/models.dart';

abstract class AuthRepository {
  Future<UserProfile> getMe();

  /// Signs into the server's public demo account (Phodex Cloud only).
  Future<UserProfile> signInAsDemo();
}
