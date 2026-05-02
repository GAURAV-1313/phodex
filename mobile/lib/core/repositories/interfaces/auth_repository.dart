import 'package:mobile/core/domain/models/models.dart';

abstract class AuthRepository {
  Future<UserProfile> getMe();
}
