import 'dart:async';
import 'dart:convert';

import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/repositories/interfaces/interfaces.dart';
import 'package:mobile/core/session/session_event_parser.dart';

class NetworkSessionStreamRepository implements SessionStreamRepository {
  const NetworkSessionStreamRepository(this._apiClient, this._parser);

  final PhodexApiClient _apiClient;
  final SessionEventParser _parser;

  @override
  Stream<TaskEventEnvelope> subscribe({
    required String taskId,
    int afterSequence = 0,
  }) async* {
    final response = await _apiClient.getStream(
      '/tasks/$taskId/stream?after_sequence=$afterSequence&live=true',
    );
    final responseBody = response.data;
    if (responseBody == null) {
      return;
    }

    final lines = responseBody.stream
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    final dataLines = <String>[];
    await for (final line in lines) {
      if (line.isEmpty) {
        if (dataLines.isNotEmpty) {
          final rawData = dataLines.join('\n');
          dataLines.clear();
          yield _parser.parse(rawData);
        }
        continue;
      }

      if (line.startsWith(':')) {
        continue;
      }

      if (line.startsWith('data:')) {
        dataLines.add(line.substring(5).trimLeft());
      }
    }

    if (dataLines.isNotEmpty) {
      yield _parser.parse(dataLines.join('\n'));
    }
  }
}
