enum ApprovalStatus { pending, approved, rejected, expired }

extension ApprovalStatusX on ApprovalStatus {
  String get value => switch (this) {
    ApprovalStatus.pending => 'pending',
    ApprovalStatus.approved => 'approved',
    ApprovalStatus.rejected => 'rejected',
    ApprovalStatus.expired => 'expired',
  };

  static ApprovalStatus fromValue(String value) {
    return switch (value) {
      'approved' => ApprovalStatus.approved,
      'rejected' => ApprovalStatus.rejected,
      'expired' => ApprovalStatus.expired,
      _ => ApprovalStatus.pending,
    };
  }
}

class ApprovalRequest {
  const ApprovalRequest({
    required this.id,
    required this.taskId,
    required this.kind,
    required this.title,
    required this.description,
    required this.payload,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
  });

  final String id;
  final String taskId;
  final String kind;
  final String title;
  final String description;
  final Map<String, dynamic> payload;
  final ApprovalStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  ApprovalRequest copyWith({
    ApprovalStatus? status,
    DateTime? resolvedAt,
    Map<String, dynamic>? payload,
  }) {
    return ApprovalRequest(
      id: id,
      taskId: taskId,
      kind: kind,
      title: title,
      description: description,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      createdAt: createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}
