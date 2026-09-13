import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/features/approvals/application/approvals_controller.dart';
import 'package:mobile/features/home/application/home_controller.dart';
import 'package:mobile/shared/theme/theme.dart';
import 'package:mobile/shared/widgets/phodex_mascot.dart';
import 'package:mobile/shared/widgets/stagger_in.dart';
import 'package:mobile/shared/widgets/stitch_nav.dart';
import 'package:mobile/shared/widgets/stitch_ui.dart';

class ApprovalsScreen extends ConsumerWidget {
  const ApprovalsScreen({super.key});

  Future<void> _resolve(
    BuildContext context,
    WidgetRef ref, {
    required String verb,
    required Future<void> Function() action,
  }) async {
    try {
      await action();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Couldn't $verb this request"),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => _resolve(context, ref, verb: verb, action: action),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(approvalsProvider);
    final tasks =
        ref.watch(homeTasksProvider).asData?.value ?? const <TaskSummary>[];
    final notifier = ref.read(approvalsProvider.notifier);

    String? taskTitleFor(String taskId) {
      for (final task in tasks) {
        if (task.id == taskId) return task.title ?? task.prompt;
      }
      return null;
    }

    return StitchScaffold(
      showDock: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.screenTop,
              AppSpacing.screen,
              0,
            ),
            child: StitchHeader(
              title: 'Approvals',
              onBack: () => stitchPopOrGo(context, '/home'),
              trailing: IconButton(
                tooltip: 'Refresh',
                onPressed: notifier.refresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ),
          ),
          Expanded(
            child: StitchAsyncView<List<ApprovalRequest>>(
              value: value,
              errorTitle: "Couldn't load approvals",
              onRetry: notifier.refresh,
              isEmpty: (items) => items.isEmpty,
              empty: const StitchEmptyState(
                mood: MascotMood.resting,
                title: 'Nothing waiting on you',
                message: 'Approval requests from your agent show up here.',
              ),
              builder: (context, items) => ListView(
                padding: stitchScreenPaddingNoDock,
                children: [
                  _SummaryCard(count: items.length),
                  const SizedBox(height: AppSpacing.s24),
                  for (final (i, item) in items.indexed)
                    StaggerIn(
                      index: i,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.s16),
                        child: _ApprovalCard(
                          approval: item,
                          taskTitle: taskTitleFor(item.taskId),
                          onApprove: () => _resolve(
                            context,
                            ref,
                            verb: 'approve',
                            action: () => notifier.approve(approvalId: item.id),
                          ),
                          onReject: () async {
                            final reason = await showRejectReasonDialog(
                              context,
                            );
                            if (reason == null || !context.mounted) return;
                            await _resolve(
                              context,
                              ref,
                              verb: 'reject',
                              action: () => notifier.reject(
                                approvalId: item.id,
                                note: reason.isEmpty ? null : reason,
                              ),
                            );
                          },
                          onViewTask: () =>
                              context.push('/session/${item.taskId}'),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) => StitchCard(
    child: Row(
      children: [
        const PhodexMascot(size: 48, mood: MascotMood.curious),
        const SizedBox(width: AppSpacing.s16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count pending',
                style: context.text.titleLarge?.copyWith(
                  color: context.colors.accentWarning,
                ),
              ),
              const SizedBox(height: AppSpacing.s4),
              Text(
                'Approvals are gated on your phone — nothing runs until you say so.',
                style: context.text.bodySmall,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ApprovalCard extends StatelessWidget {
  const _ApprovalCard({
    required this.approval,
    required this.taskTitle,
    required this.onApprove,
    required this.onReject,
    required this.onViewTask,
  });

  final ApprovalRequest approval;
  final String? taskTitle;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onViewTask;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final command = approval.payload['command']?.toString() ?? approval.title;
    final workdir = approval.payload['workdir']?.toString();
    final risk = approval.payload['risk_level']?.toString() ?? 'medium';
    final preview = workdir == null
        ? '\$ $command'
        : '\$ $command\n# in $workdir';
    return StitchCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.s12),
                decoration: BoxDecoration(
                  color: colors.accentPrimarySoft,
                  borderRadius: BorderRadius.circular(AppRadii.chip),
                ),
                child: Icon(
                  Icons.terminal_rounded,
                  color: colors.accentPrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(approval.title, style: context.text.titleMedium),
                    if (taskTitle case final title?) ...[
                      const SizedBox(height: AppSpacing.s2),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [
              const TaskStatusChip(status: 'waiting_approval'),
              _RiskChip(risk: risk),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          Text(approval.description, style: context.text.bodyMedium),
          const SizedBox(height: AppSpacing.s12),
          StitchTerminalBlock(
            text: preview,
            maxLines: 3,
            label: 'Requested action',
          ),
          const SizedBox(height: AppSpacing.s16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  child: Semantics(
                    label: 'Reject: ${approval.title}',
                    excludeSemantics: true,
                    child: const Text('Reject'),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: FilledButton(
                  onPressed: onApprove,
                  child: Semantics(
                    label: 'Approve: ${approval.title}',
                    excludeSemantics: true,
                    child: const Text('Approve'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          Center(
            child: TextButton.icon(
              onPressed: onViewTask,
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text('View full execution plan'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskChip extends StatelessWidget {
  const _RiskChip({required this.risk});
  final String risk;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = switch (risk.toLowerCase()) {
      'low' => colors.accentSuccess,
      'high' || 'critical' => colors.accentError,
      _ => colors.accentWarning,
    };
    return Semantics(
      label: '$risk risk',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s12,
          vertical: AppSpacing.s8 - AppSpacing.s2,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: colors.isDark ? .18 : .12),
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Text(
          '${risk.toUpperCase()} RISK',
          style: context.text.labelSmall?.copyWith(color: color),
        ),
      ),
    );
  }
}
