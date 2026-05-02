import 'package:flutter/material.dart';
import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/shared/theme/theme.dart';

class TaskStatusChip extends StatelessWidget {
  const TaskStatusChip({super.key, required this.status});

  final TaskStatus status;

  Color _colorForStatus() {
    return switch (status) {
      TaskStatus.running => AppColors.accentPrimary,
      TaskStatus.waitingApproval => AppColors.accentWarning,
      TaskStatus.completed => AppColors.accentSuccess,
      TaskStatus.failed || TaskStatus.cancelled => AppColors.accentError,
      _ => AppColors.textMuted,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForStatus();
    return Container(
      key: Key('task-status-chip-${status.value}'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        status.value,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
      ),
    );
  }
}
