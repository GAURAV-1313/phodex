import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/core/repositories/interfaces/interfaces.dart';
import 'package:mobile/core/repositories/mock/mock_backend_store.dart';

class MockAuthRepository implements AuthRepository {
  const MockAuthRepository(this._store);

  final MockBackendStore _store;

  @override
  Future<UserProfile> getMe() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return _store.user;
  }
}
