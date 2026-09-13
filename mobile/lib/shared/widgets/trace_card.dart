import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/shared/theme/theme.dart';
import 'package:mobile/shared/widgets/stitch_ui.dart';

/// One step of a task's execution trace: an icon for the event type, a
/// headline, the time, and — when the event carries structured data (a tool
/// call, a command, file changes, usage) — an expandable detail section.
/// Errors are tinted so a failed step stands out in a long timeline.
class TraceCard extends StatefulWidget {
  const TraceCard({
    super.key,
    required this.event,
    this.initiallyExpanded = false,
  });

  final TaskEventEnvelope event;
  final bool initiallyExpanded;

  @override
  State<TraceCard> createState() => _TraceCardState();
}

class _TraceCardState extends State<TraceCard> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final event = widget.event;
    final details = TraceDetails.of(event);
    final isError = traceIsError(event);
    final (icon, iconColor) = traceIconFor(colors, event.type);
    final accent = isError ? colors.accentError : iconColor;
    final expandable = details.isNotEmpty;
    final time = DateFormat.Hm().format(event.timestamp.toLocal());

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: 'Trace: ${event.type}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isError
              ? colors.accentError.withValues(alpha: colors.isDark ? .14 : .07)
              : colors.bgCard,
          borderRadius: BorderRadius.circular(AppRadii.global),
          border: Border.all(
            color: isError
                ? colors.accentError.withValues(alpha: .5)
                : colors.borderSubtle,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.global),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                button: expandable,
                expanded: expandable ? _expanded : null,
                child: InkWell(
                  onTap: expandable
                      ? () => setState(() => _expanded = !_expanded)
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s12,
                      vertical: AppSpacing.s12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: AppSpacing.s32,
                          height: AppSpacing.s32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accent.withValues(
                              alpha: colors.isDark ? .2 : .12,
                            ),
                          ),
                          child: Icon(icon, size: 18, color: accent),
                        ),
                        const SizedBox(width: AppSpacing.s12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                traceHeadlineFor(event),
                                style: context.text.bodyMedium?.copyWith(
                                  color: isError
                                      ? colors.accentError
                                      : colors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.s2),
                              Text(
                                '${traceTypeLabel(event.type)} · $time',
                                style: context.text.labelMedium,
                              ),
                            ],
                          ),
                        ),
                        if (expandable) ...[
                          const SizedBox(width: AppSpacing.s8),
                          AnimatedRotation(
                            turns: _expanded ? .5 : 0,
                            duration: const Duration(milliseconds: 180),
                            child: Icon(
                              Icons.expand_more_rounded,
                              color: colors.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: _expanded
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.s12,
                          0,
                          AppSpacing.s12,
                          AppSpacing.s12,
                        ),
                        child: _TraceDetailsView(details: details),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Structured payload pulled out of an event's free-form `data` map so the
/// card can render each known shape deliberately instead of dumping JSON.
class TraceDetails {
  const TraceDetails({
    this.toolType,
    this.toolStatus,
    this.command,
    this.workdir,
    this.output,
    this.fileChanges = const [],
    this.usage = const {},
    this.notes = const [],
    this.errorCode,
    this.riskLevel,
  });

  factory TraceDetails.of(TaskEventEnvelope event) {
    final data = event.data;
    final item = data['item'];
    final tool = item is Map ? item : null;

    String? str(Object? value) {
      if (value == null) return null;
      final text = value.toString().trim();
      return text.isEmpty ? null : text;
    }

    final fileChanges = <TraceFileChange>[];
    final rawChanges = data['file_changes'];
    if (rawChanges is List) {
      for (final change in rawChanges) {
        if (change is! Map) continue;
        fileChanges.add(
          TraceFileChange(
            action: str(change['action']) ?? 'changed',
            path: str(change['path']) ?? '',
            added: (change['added'] as num?)?.toInt() ?? 0,
            removed: (change['removed'] as num?)?.toInt() ?? 0,
          ),
        );
      }
    }

    final usage = <String, String>{};
    final rawUsage = data['usage'];
    if (rawUsage is Map) {
      for (final entry in rawUsage.entries) {
        final value = str(entry.value);
        if (value != null) usage[entry.key.toString()] = value;
      }
    }

    final notes = <String>[
      for (final key in const ['summary', 'description', 'content', 'note'])
        if (str(data[key]) case final text?) text,
    ];

    return TraceDetails(
      toolType: str(tool?['type'] ?? data['tool'] ?? data['tool_name']),
      toolStatus: str(tool?['status']),
      command: str(tool?['command'] ?? data['command']),
      workdir: str(data['workdir'] ?? data['cwd']),
      output: str(tool?['aggregated_output'] ?? data['output']),
      fileChanges: fileChanges,
      usage: usage,
      notes: notes,
      errorCode: str(data['error_code']),
      riskLevel: str(data['risk_level']),
    );
  }

  final String? toolType;
  final String? toolStatus;
  final String? command;
  final String? workdir;
  final String? output;
  final List<TraceFileChange> fileChanges;
  final Map<String, String> usage;
  final List<String> notes;
  final String? errorCode;
  final String? riskLevel;

  bool get isNotEmpty =>
      toolType != null ||
      command != null ||
      output != null ||
      fileChanges.isNotEmpty ||
      usage.isNotEmpty ||
      notes.isNotEmpty ||
      errorCode != null ||
      riskLevel != null;
}

class TraceFileChange {
  const TraceFileChange({
    required this.action,
    required this.path,
    required this.added,
    required this.removed,
  });

  final String action;
  final String path;
  final int added;
  final int removed;
}

class _TraceDetailsView extends StatelessWidget {
  const _TraceDetailsView({required this.details});
  final TraceDetails details;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final children = <Widget>[];

    void gap() {
      if (children.isNotEmpty) {
        children.add(const SizedBox(height: AppSpacing.s8));
      }
    }

    for (final note in details.notes) {
      gap();
      children.add(Text(note, style: context.text.bodySmall));
    }

    if (details.errorCode != null) {
      gap();
      children.add(
        Semantics(
          label: 'Error ${details.errorCode}',
          child: Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 16,
                color: colors.accentError,
              ),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: Text(
                  details.errorCode!,
                  style: AppTypography.code(color: colors.accentError),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (details.riskLevel != null) {
      gap();
      children.add(
        Text(
          'Risk: ${details.riskLevel}',
          style: context.text.labelMedium?.copyWith(
            color: colors.accentWarning,
          ),
        ),
      );
    }

    if (details.toolType != null || details.command != null) {
      gap();
      final label = [
        if (details.toolType != null) traceTypeLabel(details.toolType!),
        if (details.toolStatus != null) details.toolStatus!,
      ].join(' · ');
      final buffer = StringBuffer();
      if (details.command != null) buffer.write('\$ ${details.command}');
      if (details.workdir != null) {
        if (buffer.isNotEmpty) buffer.write('\n');
        buffer.write('# in ${details.workdir}');
      }
      if (details.output != null) {
        if (buffer.isNotEmpty) buffer.write('\n');
        buffer.write(details.output);
      }
      children.add(
        Semantics(
          label: 'Tool call',
          child: StitchTerminalBlock(
            text: buffer.toString(),
            label: label.isEmpty ? 'Tool call' : label,
            maxLines: 12,
          ),
        ),
      );
    } else if (details.output != null) {
      gap();
      children.add(
        StitchTerminalBlock(
          text: details.output!,
          label: 'Output',
          maxLines: 12,
        ),
      );
    }

    if (details.fileChanges.isNotEmpty) {
      gap();
      children.add(
        Semantics(
          label: '${details.fileChanges.length} file changes',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('FILE CHANGES', style: context.text.labelSmall),
              const SizedBox(height: AppSpacing.s4),
              for (final change in details.fileChanges)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.s4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: AppSpacing.s48 + AppSpacing.s24,
                        child: Text(
                          change.action,
                          style: context.text.labelMedium?.copyWith(
                            color: _actionColor(colors, change.action),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          change.path,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.code(color: colors.textPrimary),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      Text(
                        '+${change.added}',
                        style: AppTypography.code(color: colors.accentSuccess),
                      ),
                      const SizedBox(width: AppSpacing.s4),
                      Text(
                        '−${change.removed}',
                        style: AppTypography.code(color: colors.accentError),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    }

    if (details.usage.isNotEmpty) {
      gap();
      children.add(
        Semantics(
          label: 'Usage',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('USAGE', style: context.text.labelSmall),
              const SizedBox(height: AppSpacing.s4),
              for (final entry in details.usage.entries)
                Text(
                  '${entry.key}: ${entry.value}',
                  style: AppTypography.code(color: colors.textSecondary),
                ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  static Color _actionColor(AppColors colors, String action) =>
      switch (action.toLowerCase()) {
        'created' || 'added' => colors.accentSuccess,
        'deleted' || 'removed' => colors.accentError,
        _ => colors.accentPrimary,
      };
}

// ------------------------------------------------------------- helpers

/// Icon and tint for an event type — shared by the timeline and the
/// logs sheet so the same kind of step always looks the same.
(IconData, Color) traceIconFor(
  AppColors colors,
  String eventType,
) => switch (eventType) {
  'task.created' => (Icons.add_circle_outline_rounded, colors.accentPrimary),
  'task.starting' => (Icons.play_circle_outline_rounded, colors.accentPrimary),
  'task.running' => (Icons.autorenew_rounded, colors.accentPrimary),
  'task.progress' => (Icons.chat_bubble_outline_rounded, colors.textSecondary),
  'task.completed' => (Icons.check_circle_rounded, colors.accentSuccess),
  'task.failed' => (Icons.error_rounded, colors.accentError),
  'task.cancelled' => (Icons.stop_circle_rounded, colors.textMuted),
  'task.log' || 'git.log' => (Icons.terminal_rounded, colors.textMuted),
  'approval.requested' => (Icons.gpp_maybe_outlined, colors.accentWarning),
  'approval.approved' => (Icons.verified_rounded, colors.accentSuccess),
  'approval.rejected' => (Icons.block_rounded, colors.accentError),
  'git.started' => (Icons.upload_rounded, colors.accentPrimary),
  'git.completed' => (Icons.cloud_done_rounded, colors.accentSuccess),
  'git.failed' => (Icons.error_rounded, colors.accentError),
  'git.discarded' => (Icons.stop_circle_rounded, colors.textMuted),
  _ when eventType.startsWith('tool.') => (
    Icons.build_circle_outlined,
    colors.accentPrimary,
  ),
  _ => (Icons.circle_outlined, colors.textMuted),
};

/// Whether the step represents something going wrong.
bool traceIsError(TaskEventEnvelope event) =>
    event.type.endsWith('.failed') ||
    event.type == 'approval.rejected' ||
    event.data['error_code'] != null ||
    event.data['error'] != null;

/// "task.progress" → "Task progress", "approval_requested" → "Approval
/// requested".
String traceTypeLabel(String type) {
  final words = type.replaceAll('.', ' ').replaceAll('_', ' ').trim();
  if (words.isEmpty) return type;
  return words[0].toUpperCase() + words.substring(1);
}

/// The one-line summary of an event: its message when the backend sent
/// one, else the command it ran, else its title, else the type itself.
String traceHeadlineFor(TaskEventEnvelope event) {
  final data = event.data;
  final item = data['item'];
  final candidates = <Object?>[
    data['message'],
    data['title'],
    if (item is Map) item['command'],
    data['command'],
  ];
  for (final candidate in candidates) {
    final text = candidate?.toString().trim();
    if (text != null && text.isNotEmpty) {
      return text[0].toUpperCase() + text.substring(1);
    }
  }
  return traceTypeLabel(event.type);
}
