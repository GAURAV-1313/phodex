import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/features/approvals/application/approvals_controller.dart';
import 'package:mobile/shared/theme/theme.dart';
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
                  const Spacer(),
                  const Text(
                    'Phodex',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 70),
              if (items.isEmpty)
                const _NoApprovals()
              else ...[
                const Text(
                  'Pending Approval',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 38,
                    letterSpacing: -1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Your AI engineer needs permission to continue an important action.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 19,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 58),
                for (final item in items)
                  _ApprovalReview(
                    approval: item,
                    onApprove: () => ref
                        .read(approvalsProvider.notifier)
                        .approve(approvalId: item.id),
                    onReject: () => ref
                        .read(approvalsProvider.notifier)
                        .reject(approvalId: item.id),
                    onTask: () => context.go('/session/${item.taskId}'),
                  ),
              ],
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              Center(child: Text('Could not load approvals: $error')),
        ),
      ),
    );
  }
}

class _NoApprovals extends StatelessWidget {
  const _NoApprovals();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(top: 160),
    child: Column(
      children: [
        Icon(
          Icons.verified_user_outlined,
          size: 72,
          color: AppColors.accentSuccess,
        ),
        SizedBox(height: 20),
        Text(
          'Nothing needs your approval',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 10),
        Text(
          'Your agent will pause here whenever it needs a decision.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 17),
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
              const Expanded(
                child: Text(
                  'REPOSITORY',
                  style: TextStyle(
                    letterSpacing: 1.3,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              Chip(label: Text('$risk risk'.toUpperCase())),
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
              style: const TextStyle(
                fontFamily: 'monospace',
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
          StitchPrimaryButton(label: 'Approve', onPressed: onApprove),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.tonal(
              onPressed: onReject,
              child: const Text('Reject'),
            ),
          ),
        ],
      ),
    );
  }
}
