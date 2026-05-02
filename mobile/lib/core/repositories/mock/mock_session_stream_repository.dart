import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/core/repositories/interfaces/interfaces.dart';
import 'package:mobile/core/repositories/mock/mock_backend_store.dart';

class MockSessionStreamRepository implements SessionStreamRepository {
  const MockSessionStreamRepository(this._store);

  final MockBackendStore _store;

  @override
  Stream<TaskEventEnvelope> subscribe({
    required String taskId,
    int afterSequence = 0,
  }) {
    return _store.subscribeToEvents(
      taskId: taskId,
      afterSequence: afterSequence,
    );
  }
}
