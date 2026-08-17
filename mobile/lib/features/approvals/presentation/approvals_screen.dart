import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/features/approvals/application/approvals_controller.dart';
import 'package:mobile/shared/theme/theme.dart';
import 'package:mobile/shared/widgets/phodex_mascot.dart';
import 'package:mobile/shared/widgets/stagger_in.dart';
import 'package:mobile/shared/widgets/stitch_ui.dart';

class ApprovalsScreen extends ConsumerWidget {
  const ApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(approvalsProvider);
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: value.when(
          data: (items) => ListView(
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 44),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 70),
              if (items.isEmpty)
                const _NoApprovals()
              else ...[
                Text(
                  'Pending Approval',
                  textAlign: TextAlign.center,
                  style: AppTypography.display(
                    fontSize: AppTypeScale.displayLarge,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Your AI engineer needs permission to continue an important action.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppTypeScale.subhead,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 58),
                for (final (i, item) in items.indexed)
                  StaggerIn(
                    index: i,
                    child: _ApprovalReview(
                      approval: item,
                      onApprove: () => ref
                          .read(approvalsProvider.notifier)
                          .approve(approvalId: item.id),
                      onReject: () => ref
                          .read(approvalsProvider.notifier)
                          .reject(approvalId: item.id),
                      onTask: () => context.go('/session/${item.taskId}'),
                    ),
                  ),
              ],
            ],
          ),
          loading: () => const PhodexLoading(),
          error: (error, _) => StitchErrorState(
            title: "Couldn't load approvals",
            onRetry: () => ref.invalidate(approvalsProvider),
          ),
        ),
      ),
    );
  }
}

class _NoApprovals extends StatelessWidget {
  const _NoApprovals();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 140),
    child: Column(
      children: [
        const PhodexMascot(size: 84, mood: MascotMood.success),
        const SizedBox(height: 24),
        Text(
          'Nothing needs your approval',
          style: AppTypography.display(fontSize: AppTypeScale.title),
        ),
        const SizedBox(height: 10),
        const Text(
          'Your agent will pause here whenever it needs a decision.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: AppTypeScale.body,
          ),
        ),
      ],
    ),
  );
}

class _ApprovalReview extends StatelessWidget {
  const _ApprovalReview({
    required this.approval,
    required this.onApprove,
    required this.onReject,
    required this.onTask,
  });
  final ApprovalRequest approval;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onTask;

  @override
  Widget build(BuildContext context) {
    final command = approval.payload['command']?.toString() ?? approval.title;
    final risk = approval.payload['risk_level']?.toString() ?? 'medium';
    final kindLabel = approval.kind
        .split('_')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
    return StitchCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F2FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.terminal_rounded,
                  color: AppColors.accentPrimary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  kindLabel.isEmpty ? 'ACTION' : kindLabel.toUpperCase(),
                  style: const TextStyle(
                    letterSpacing: 1.3,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              _RiskBadge(risk: risk),
            ],
          ),
          const SizedBox(height: 22),
          const Divider(),
          const SizedBox(height: 22),
          const Text(
            'TASK DESCRIPTION',
            style: TextStyle(
              letterSpacing: 1.3,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            approval.title,
            style: const TextStyle(
              fontSize: 29,
              height: 1.12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'REQUESTED ACTION',
            style: TextStyle(
              letterSpacing: 1.3,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgInput,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              '\$ $command',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.code(
                fontSize: 15,
                color: AppColors.accentPrimary,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            approval.description,
            style: const TextStyle(
              fontSize: 18,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 22),
          Center(
            child: TextButton(
              onPressed: onTask,
              child: const Text('View full execution plan'),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.borderSubtle),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StitchPrimaryButton(
                  label: 'Approve',
                  onPressed: onApprove,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RiskBadge extends StatelessWidget {
  const _RiskBadge({required this.risk});
  final String risk;

  @override
  Widget build(BuildContext context) {
    final color = switch (risk.toLowerCase()) {
      'low' => AppColors.accentSuccess,
      'high' || 'critical' => AppColors.accentError,
      _ => AppColors.accentWarning,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${risk.toUpperCase()} RISK',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: .4,
          color: color,
        ),
      ),
    );
  }
}
