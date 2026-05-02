import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/core/session/session_event_ordering.dart';
import 'package:mobile/features/session/application/session_event_reducer.dart';
import 'package:mobile/features/session/application/session_state.dart';

void main() {
  TaskEventEnvelope event({
    required int sequence,
    required String type,
    Map<String, dynamic> data = const <String, dynamic>{},
  }) {
    return TaskEventEnvelope(
      eventId: 'evt_$sequence',
      taskId: 'task_1',
      sequence: sequence,
      type: type,
      timestamp: DateTime.parse(
        '2026-04-22T12:00:00Z',
      ).add(Duration(seconds: sequence)),
      data: data,
    );
  }

  SessionUiState baseState() {
    return SessionUiState(
      task: TaskSummary(
        id: 'task_1',
        userId: 'usr_1',
        projectContextId: null,
        title: 'Task',
        prompt: 'Prompt',
        status: TaskStatus.running,
        currentPhase: 'running',
        createdAt: DateTime.parse('2026-04-22T11:00:00Z'),
        updatedAt: DateTime.parse('2026-04-22T11:00:00Z'),
      ),
      messages: const [],
      events: [event(sequence: 1, type: 'task.created')],
      approvals: const [],
      issues: const [],
    );
  }

  test('mergeOrderedEvents sorts and deduplicates by sequence', () {
    final merged = mergeOrderedEvents(
      [
        event(sequence: 1, type: 'task.created'),
        event(sequence: 3, type: 'task.running'),
      ],
      [
        event(sequence: 2, type: 'task.starting'),
        event(sequence: 3, type: 'task.progress'),
      ],
    );

    expect(merged.length, 3);
    expect(merged[0].sequence, 1);
    expect(merged[1].sequence, 2);
    expect(merged[2].type, 'task.progress');
  });

  test('reduceSessionWithEvent updates task status and issues', () {
    final failedEvent = event(
      sequence: 2,
      type: 'task.failed',
      data: const {'message': 'Worker failed', 'error_code': 'WORKER_ERROR'},
    );

    final reduced = reduceSessionWithEvent(baseState(), failedEvent);

    expect(reduced.task.status, TaskStatus.failed);
    expect(reduced.issues.length, 1);
    expect(reduced.issues.first.code, 'WORKER_ERROR');
    expect(reduced.events.last.sequence, 2);
  });
}
