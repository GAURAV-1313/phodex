import 'package:flutter/material.dart';
import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/shared/theme/theme.dart';

class IssueCard extends StatelessWidget {
  const IssueCard({super.key, required this.issue});

  final TaskIssue issue;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('issue-card-${issue.sequence}'),
      margin: const EdgeInsets.only(bottom: AppSpacing.s12),
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: context.colors.accentError.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: context.colors.accentError.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            issue.code ?? issue.type,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.colors.accentError,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(issue.message, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
