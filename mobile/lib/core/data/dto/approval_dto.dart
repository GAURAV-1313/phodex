import 'package:mobile/core/data/dto/common_dto.dart';
import 'package:mobile/core/domain/models/models.dart';

class ApprovalRequestOutDto {
  const ApprovalRequestOutDto({
    required this.id,
    required this.taskId,
    required this.kind,
    required this.title,
    required this.description,
    required this.payloadJson,
    required this.status,
    required this.createdAt,
    required this.resolvedAt,
  });

  final String id;
  final String taskId;
  final String kind;
  final String title;
  final String description;
  final Map<String, dynamic> payloadJson;
  final ApprovalStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  factory ApprovalRequestOutDto.fromJson(Map<String, dynamic> json) {
    return ApprovalRequestOutDto(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      kind: json['kind'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      payloadJson:
          (json['payload_json'] as Map<String, dynamic>?) ??
          <String, dynamic>{},
      status: ApprovalStatusX.fromValue(json['status'] as String),
      createdAt: parseDateTime(json['created_at']),
      resolvedAt: parseNullableDateTime(json['resolved_at']),
    );
  }

  ApprovalRequest toDomain() {
    return ApprovalRequest(
      id: id,
      taskId: taskId,
      kind: kind,
      title: title,
      description: description,
      payload: payloadJson,
      status: status,
      createdAt: createdAt,
      resolvedAt: resolvedAt,
    );
  }
}

class PendingApprovalsResponseDto {
  const PendingApprovalsResponseDto({required this.items});

  final List<ApprovalRequestOutDto> items;

  factory PendingApprovalsResponseDto.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List<dynamic>? ?? <dynamic>[])
        .cast<Map<String, dynamic>>();
    return PendingApprovalsResponseDto(
      items: rawItems.map(ApprovalRequestOutDto.fromJson).toList(),
    );
  }
}
