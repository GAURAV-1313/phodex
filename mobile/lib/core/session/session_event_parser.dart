import 'dart:convert';

import 'package:mobile/core/data/dto/task_dto.dart';
import 'package:mobile/core/domain/models/models.dart';

abstract class SessionEventParser {
  TaskEventEnvelope parse(String rawData);
}

class JsonSessionEventParser implements SessionEventParser {
  const JsonSessionEventParser();

  @override
  TaskEventEnvelope parse(String rawData) {
    final decoded = jsonDecode(rawData) as Map<String, dynamic>;
    return TaskEventEnvelopeDto.fromJson(decoded).toDomain();
  }
}
