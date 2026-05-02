import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/features/approvals/application/approvals_controller.dart';
import 'package:mobile/shared/widgets/template_kit.dart';

class ApprovalsScreen extends ConsumerWidget {
  const ApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final approvalsValue = ref.watch(approvalsProvider);

    return TemplateScaffold(
      key: const Key('approvals-screen'),
      bottomSafeArea: true,
      child: RefreshIndicator(
        onRefresh: () => ref.read(approvalsProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(17, 0, 17, 28),
          children: [
            const TemplateStatusBar(),
            Row(
              children: [
                const Text(
                  'Review approvals',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 34,
                    height: 42 / 34,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                TemplateIcon(
                  icon: Icons.close_rounded,
                  onTap: () => context.go('/home'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            approvalsValue.when(
              data: (approvals) {
                if (approvals.isEmpty) {
                  return const _EmptyApprovals();
                }
                return Column(
                  children: [
                    for (final approval in approvals)
                      _ApprovalCard(
                        approval: approval,
                        onOpenTask: () =>
                            context.go('/session/${approval.taskId}'),
                        onApprove: () async {
                          await ref
                              .read(approvalsProvider.notifier)
                              .approve(approvalId: approval.id);
                        },
                        onReject: () async {
                          await ref
                              .read(approvalsProvider.notifier)
                              .reject(approvalId: approval.id);
                        },
                      ),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 160),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => _ErrorBlock(
                message: 'Could not load approvals: $error',
                onRetry: () => ref.read(approvalsProvider.notifier).refresh(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  const _ApprovalCard({
    required this.approval,
    required this.onOpenTask,
    required this.onApprove,
    required this.onReject,
  });

  final ApprovalRequest approval;
  final VoidCallback onOpenTask;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final risk = approval.payload['risk_level'] as String? ?? approval.kind;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TemplateColors.promptBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onOpenTask,
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.black),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    approval.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 17,
                      height: 22 / 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  risk,
                  style: const TextStyle(
                    color: TemplateColors.labelSecondary,
                    fontSize: 13,
                    height: 18 / 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            approval.description,
            style: const TextStyle(
              color: TemplateColors.labelSecondary,
              fontSize: 15,
              height: 20 / 15,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ApprovalAction(
                  title: 'Approve',
                  filled: true,
                  onTap: onApprove,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ApprovalAction(title: 'Reject', onTap: onReject),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyApprovals extends StatelessWidget {
  const _EmptyApprovals();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 160),
      child: Column(
        children: [
          Icon(Icons.mark_email_read_outlined, color: Colors.black, size: 84),
          SizedBox(height: 19),
          Text(
            'No pending approvals',
            style: TextStyle(
              color: Colors.black,
              fontSize: 28,
              height: 34 / 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Risky commands and file changes will appear here before Phodex continues.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: TemplateColors.labelSecondary,
              fontSize: 17,
              height: 22 / 17,
            ),
          ),
        ],
      ),
    );
  }
}

class _ApprovalAction extends StatelessWidget {
  const _ApprovalAction({
    required this.title,
    required this.onTap,
    this.filled = false,
  });

  final String title;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: filled ? null : Border.all(color: TemplateColors.separator),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: filled ? Colors.white : Colors.black,
            fontSize: 15,
            height: 20 / 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 120),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: TemplateColors.labelSecondary),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
