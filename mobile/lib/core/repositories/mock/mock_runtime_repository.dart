import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/core/repositories/interfaces/interfaces.dart';
import 'package:mobile/core/repositories/mock/mock_backend_store.dart';

class MockRuntimeRepository implements RuntimeRepository {
  const MockRuntimeRepository(this._store);

  final MockBackendStore _store;

  @override
  Future<RuntimeInfo> getRuntimeInfo() async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    return _store.getRuntimeInfo();
  }
}
