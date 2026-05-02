import 'package:mobile/core/domain/models/models.dart';

List<TaskEventEnvelope> mergeOrderedEvents(
  List<TaskEventEnvelope> current,
  List<TaskEventEnvelope> incoming,
) {
  final bySequence = <int, TaskEventEnvelope>{
    for (final event in current) event.sequence: event,
  };

  for (final event in incoming) {
    bySequence[event.sequence] = event;
  }

  final sorted = bySequence.values.toList()
    ..sort((a, b) => a.sequence.compareTo(b.sequence));
  return sorted;
}
