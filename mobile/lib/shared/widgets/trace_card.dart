import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/shared/theme/theme.dart';

class TraceCard extends StatefulWidget {
  const TraceCard({super.key, required this.event});

  final TaskEventEnvelope event;

  @override
  State<TraceCard> createState() => _TraceCardState();
}

class _TraceCardState extends State<TraceCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final time = DateFormat.Hm().format(event.timestamp.toLocal());
    final message = (event.data['message'] as String?) ?? event.type;

    return Card(
      key: Key('trace-card-${event.sequence}'),
      margin: const EdgeInsets.only(bottom: AppSpacing.s12),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.card),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accentPrimary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  Expanded(
                    child: Text(
                      event.type,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(time, style: Theme.of(context).textTheme.labelMedium),
                ],
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(message, style: Theme.of(context).textTheme.bodyLarge),
              if (_expanded && event.data.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.s12),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Text(
                    event.data.entries
                        .map((entry) => '${entry.key}: ${entry.value}')
                        .join('\n'),
                    style: AppTypography.code,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
