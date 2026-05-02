import 'package:mobile/core/domain/models/models.dart';

abstract class SessionStreamRepository {
  Stream<TaskEventEnvelope> subscribe({
    required String taskId,
    int afterSequence = 0,
  });
}
