import 'package:flutter/material.dart';
import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/shared/theme/theme.dart';

class ContextPill extends StatelessWidget {
  const ContextPill({super.key, required this.contextModel});

  final ProjectContext contextModel;

  @override
  Widget build(BuildContext context) {
    final repoName = contextModel.name;
    final branch = contextModel.branch ?? 'unknown';

    return Container(
      key: const Key('context-pill'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s8,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.folder_open_rounded,
            size: 16,
            color: AppColors.accentPrimary,
          ),
          const SizedBox(width: AppSpacing.s8),
          Flexible(
            child: Text(
              '$repoName • $branch',
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
