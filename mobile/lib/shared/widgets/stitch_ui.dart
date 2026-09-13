import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/shared/theme/theme.dart';
import 'package:mobile/shared/widgets/phodex_mascot.dart';

/// The shared UI kit ("Stitch"). Every screen is assembled from these pieces
/// and the tokens in `shared/theme`, so nothing in `features/` should ever
/// need a raw color, a literal font size, or a literal corner radius — the
/// `tool/check_design_tokens.sh` lint guard enforces exactly that.

/// Height reserved for the floating dock + its clear-space gradient. Screens
/// with a [StitchScaffold] should use at least this much bottom padding on
/// their scrollable content so nothing sits hidden behind the dock at rest.
const double stitchDockClearance = 128;

/// Standard screen content inset: [AppSpacing.screen] on the sides, the
/// header gap on top, and dock clearance at the bottom.
const EdgeInsets stitchScreenPadding = EdgeInsets.fromLTRB(
  AppSpacing.screen,
  AppSpacing.screenTop,
  AppSpacing.screen,
  stitchDockClearance,
);

/// Same as [stitchScreenPadding] for screens without a dock.
const EdgeInsets stitchScreenPaddingNoDock = EdgeInsets.fromLTRB(
  AppSpacing.screen,
  AppSpacing.screenTop,
  AppSpacing.screen,
  AppSpacing.screen,
);

/// Standard loading state — the mascot mid-thought instead of a generic
/// platform spinner, used everywhere the app is waiting on the backend.
class PhodexLoading extends StatelessWidget {
  const PhodexLoading({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) => Center(
    child: Semantics(
      label: message ?? 'Loading',
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PhodexMascot(size: 64, mood: MascotMood.thinking),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.s16),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium,
            ),
          ],
        ],
      ),
    ),
  );
}

/// The shell for every tab-level screen: themed background, safe area, the
/// bottom fade, and the floating dock. Detail screens that should not show
/// the dock pass [showDock] = false and still get the same background and
/// safe area, so the whole app shares one shell.
class StitchScaffold extends StatelessWidget {
  const StitchScaffold({
    super.key,
    required this.child,
    this.active = StitchTab.home,
    this.showDock = true,
    this.bottom,
  });

  final Widget child;
  final StitchTab active;
  final bool showDock;

  /// Something pinned above the safe-area bottom (a composer, an action
  /// bar). Rendered instead of the dock.
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.bgPrimary,
      resizeToAvoidBottomInset: bottom != null,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: child),
            if (showDock && bottom == null) ...[
              // Fades scrolled content out before it reaches the dock, so
              // anything passing underneath never looks abruptly clipped.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 116,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          colors.bgPrimary.withValues(alpha: 0),
                          colors.bgPrimary,
                        ],
                        stops: const [0.0, 0.62],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: AppSpacing.s20,
                right: AppSpacing.s20,
                bottom: AppSpacing.s16,
                child: StitchDock(active: active),
              ),
            ],
            if (bottom != null)
              Positioned(left: 0, right: 0, bottom: 0, child: bottom!),
          ],
        ),
      ),
    );
  }
}

enum StitchTab { home, activity, repos, account }

class StitchDock extends StatelessWidget {
  const StitchDock({super.key, required this.active});
  final StitchTab active;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final items = <(StitchTab, IconData?, String, String)>[
      (StitchTab.home, null, 'Agents', '/home'),
      (StitchTab.activity, Icons.assignment_outlined, 'Tasks', '/activity'),
      (StitchTab.repos, Icons.folder_outlined, 'Repos', '/repos'),
      (StitchTab.account, Icons.person_outline, 'Account', '/account'),
    ];
    return Container(
      height: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        boxShadow: [
          BoxShadow(
            color: colors.shadowStrong,
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8),
            decoration: BoxDecoration(
              color: colors.bgSurface.withValues(alpha: .78),
              border: Border.all(color: colors.bgSurface.withValues(alpha: .6)),
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
            child: Row(
              children: [
                for (final item in items)
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: active == item.$1,
                      label: '${item.$3} tab',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                        onTap: () => context.go(item.$4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (item.$2 == null)
                              PhodexMascotGlyph(
                                size: 24,
                                color: active == item.$1
                                    ? colors.accentPrimary
                                    : colors.textSecondary,
                              )
                            else
                              Icon(
                                item.$2,
                                color: active == item.$1
                                    ? colors.accentPrimary
                                    : colors.textSecondary,
                              ),
                            const SizedBox(height: AppSpacing.s2),
                            Text(
                              item.$3,
                              style: context.text.labelSmall?.copyWith(
                                letterSpacing: 0,
                                color: active == item.$1
                                    ? colors.accentPrimary
                                    : colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The one and only back affordance. Detail screens must use this (via
/// [StitchHeader.onBack]) rather than their own icon so "back" looks and
/// behaves the same everywhere.
class StitchBackButton extends StatelessWidget {
  const StitchBackButton({super.key, this.onPressed, this.label = 'Back'});

  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) => IconButton(
    key: const Key('stitch-back-button'),
    tooltip: label,
    onPressed: onPressed ?? () => _pop(context),
    icon: Icon(
      Icons.arrow_back_ios_new_rounded,
      color: context.colors.accentPrimary,
    ),
  );

  static void _pop(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }
}

/// A screen's top row. On top-level tab screens (no [onBack], no [title])
/// the mascot itself is the brand mark — no "Phodex" wordmark repeated on
/// every screen. Detail screens pass [title] and [onBack] for real
/// navigational context instead.
class StitchHeader extends StatelessWidget {
  const StitchHeader({
    super.key,
    this.title,
    this.onBell,
    this.onBack,
    this.bellBadge = false,
    this.trailing,
    this.mood = MascotMood.idle,
  });

  final String? title;
  final VoidCallback? onBell;
  final VoidCallback? onBack;

  /// Show the unread dot on the bell — only when something is actually
  /// pending, never as decoration.
  final bool bellBadge;

  /// Replaces the bell with a custom trailing widget (e.g. a refresh action).
  final Widget? trailing;
  final MascotMood mood;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      if (onBack != null)
        StitchBackButton(onPressed: onBack)
      else
        PhodexMascot(size: 40, mood: mood),
      const SizedBox(width: AppSpacing.s12),
      if (title != null)
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title!,
              overflow: TextOverflow.ellipsis,
              style: context.text.headlineMedium,
            ),
          ),
        )
      else
        const Spacer(),
      if (trailing != null)
        trailing!
      else if (onBell != null)
        IconButton(
          tooltip: 'Notifications',
          onPressed: onBell,
          icon: Badge(
            isLabelVisible: bellBadge,
            smallSize: 7,
            child: const Icon(Icons.notifications_none_rounded, size: 28),
          ),
        ),
    ],
  );
}

/// Eyebrow label above a group of content ("RECENT", "PENDING").
class StitchSectionLabel extends StatelessWidget {
  const StitchSectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.s12),
    child: Row(
      children: [
        Expanded(
          child: Text(text.toUpperCase(), style: context.text.labelSmall),
        ),
        if (trailing != null) trailing!,
      ],
    ),
  );
}

class StitchCard extends StatelessWidget {
  const StitchCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.s20),
    this.onTap,
    this.color,
    this.border,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? color;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: border,
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 24,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: color ?? colors.bgCard,
        borderRadius: BorderRadius.circular(AppRadii.card),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class StitchPrimaryButton extends StatelessWidget {
  const StitchPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// Shows a spinner in place of the icon and disables the button.
  final bool loading;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 58,
    width: double.infinity,
    child: FilledButton.icon(
      onPressed: loading ? null : onPressed,
      icon: loading
          ? SizedBox(
              width: AppSpacing.s20,
              height: AppSpacing.s20,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: context.colors.onAccent,
              ),
            )
          : (icon == null ? const SizedBox.shrink() : Icon(icon)),
      label: Text(
        label,
        style: context.text.titleMedium?.copyWith(
          color: context.colors.onAccent,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

/// The quieter sibling of [StitchPrimaryButton] for secondary choices that
/// still deserve a full-width target ("Enter address manually", "Skip").
class StitchSecondaryButton extends StatelessWidget {
  const StitchSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 58,
    width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon == null ? const SizedBox.shrink() : Icon(icon),
      label: Text(
        label,
        style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
  );
}

// ---------------------------------------------------------------- status

Color taskStatusColor(AppColors colors, String value) => switch (value) {
  'completed' => colors.accentSuccess,
  'waiting_approval' => colors.accentWarning,
  'failed' => colors.accentError,
  'cancelled' => colors.textMuted,
  _ => colors.accentPrimary,
};

String taskStatusLabel(String value) => switch (value) {
  'queued' => 'Queued',
  'starting' => 'Starting',
  'running' => 'Running',
  'waiting_approval' => 'Needs approval',
  'completed' => 'Completed',
  'failed' => 'Failed',
  'cancelled' => 'Cancelled',
  _ => value.replaceAll('_', ' '),
};

/// The spec's `TaskStatusChip`: one pill for a task's status, used on
/// cards, the session header, and approvals alike.
class TaskStatusChip extends StatelessWidget {
  const TaskStatusChip({
    super.key,
    required this.status,
    this.compact = false,
    this.pulse = false,
  });

  /// Raw backend status value (`running`, `waiting_approval`, …).
  final String status;
  final bool compact;

  /// Animates the dot while live events are arriving.
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    final color = taskStatusColor(context.colors, status);
    final label = taskStatusLabel(status);
    return Semantics(
      label: 'Status: $label',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? AppSpacing.s8 : AppSpacing.s12,
          vertical: compact ? AppSpacing.s4 : AppSpacing.s8 - AppSpacing.s2,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: context.colors.isDark ? .18 : .12),
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PulseDot(color: color, pulse: pulse),
            const SizedBox(width: AppSpacing.s8),
            Text(
              label,
              style:
                  (compact ? context.text.labelMedium : context.text.labelLarge)
                      ?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color, required this.pulse});
  final Color color;
  final bool pulse;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    if (widget.pulse) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _PulseDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulse && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.pulse && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) => Container(
      width: AppSpacing.s8,
      height: AppSpacing.s8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.color.withValues(alpha: 1 - _controller.value * .6),
      ),
    ),
  );
}

/// The spec's `ContextPill`: which repository (and branch) a task or the
/// composer is pointed at. Tappable when the user can change it.
class ContextPill extends StatelessWidget {
  const ContextPill({
    super.key,
    required this.name,
    this.branch,
    this.onTap,
    this.icon = Icons.folder_outlined,
    this.emphasized = false,
  });

  final String name;
  final String? branch;
  final VoidCallback? onTap;
  final IconData icon;

  /// Uses the accent tint (e.g. when no repo is selected and the pill is a
  /// call to action).
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fg = emphasized ? colors.accentPrimaryDeep : colors.textSecondary;
    return Semantics(
      button: onTap != null,
      label: branch == null
          ? 'Repository $name'
          : 'Repository $name on $branch',
      child: Material(
        color: emphasized ? colors.accentPrimarySoft : colors.bgInput,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s12,
              vertical: AppSpacing.s8,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: AppSpacing.s8),
                Flexible(
                  child: Text(
                    branch == null ? name : '$name · $branch',
                    overflow: TextOverflow.ellipsis,
                    style: context.text.labelMedium?.copyWith(color: fg),
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: AppSpacing.s4),
                  Icon(Icons.expand_more_rounded, size: 16, color: fg),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------- state views

/// Empty state with the mascot. Every list-like screen uses this (never an
/// ad-hoc icon + text) so "nothing here yet" looks the same everywhere and
/// always offers a way forward when one exists.
class StitchEmptyState extends StatelessWidget {
  const StitchEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.mood = MascotMood.resting,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  final String title;
  final String message;
  final MascotMood mood;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PhodexMascot(size: 72, mood: mood),
          const SizedBox(height: AppSpacing.s20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: context.text.titleLarge,
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: context.text.bodyMedium,
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: AppSpacing.s24),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
          if (secondaryActionLabel != null) ...[
            const SizedBox(height: AppSpacing.s8),
            TextButton(
              onPressed: onSecondaryAction,
              child: Text(secondaryActionLabel!),
            ),
          ],
        ],
      ),
    ),
  );
}

/// Friendly error state for async views — never surfaces the raw exception
/// text (stack traces, HTTP client internals) to the user.
class StitchErrorState extends StatelessWidget {
  const StitchErrorState({
    super.key,
    this.title = "Something didn't load",
    this.message = 'Check your connection and try again.',
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PhodexMascot(size: 72, mood: MascotMood.error),
          const SizedBox(height: AppSpacing.s20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: context.text.titleLarge,
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: context.text.bodyMedium,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.s24),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try again'),
            ),
          ],
        ],
      ),
    ),
  );
}

/// Renders the loading / error / empty / data quartet for an [AsyncValue]
/// the same way on every screen. While a refresh is in flight the previous
/// data stays on screen (no flash back to the mascot spinner).
class StitchAsyncView<T> extends StatelessWidget {
  const StitchAsyncView({
    super.key,
    required this.value,
    required this.builder,
    this.isEmpty,
    this.empty,
    this.onRetry,
    this.errorTitle = "Something didn't load",
    this.errorMessage = 'Check your connection and try again.',
    this.loadingMessage,
    this.loading,
  });

  final AsyncValue<T> value;
  final Widget Function(BuildContext context, T data) builder;
  final bool Function(T data)? isEmpty;
  final Widget? empty;
  final VoidCallback? onRetry;
  final String errorTitle;
  final String errorMessage;
  final String? loadingMessage;

  /// Custom loading view (e.g. a skeleton) instead of the mascot spinner.
  final Widget? loading;

  @override
  Widget build(BuildContext context) {
    if (value.hasValue) {
      final data = value.requireValue;
      if (isEmpty != null && empty != null && isEmpty!(data)) return empty!;
      return builder(context, data);
    }
    if (value.hasError) {
      return StitchErrorState(
        title: errorTitle,
        message: errorMessage,
        onRetry: onRetry,
      );
    }
    return loading ?? PhodexLoading(message: loadingMessage);
  }
}

// ----------------------------------------------------------------- banner

enum StatusTone { info, success, warning, error }

/// Inline banner for transient conditions ("Reconnecting…", "Desktop is
/// offline") — pinned inside the screen, never a snackbar that disappears
/// while the condition persists.
class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.message,
    this.tone = StatusTone.info,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.busy = false,
  });

  final String message;
  final StatusTone tone;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Shows a small progress indicator instead of the icon.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = switch (tone) {
      StatusTone.info => colors.accentPrimary,
      StatusTone.success => colors.accentSuccess,
      StatusTone.warning => colors.accentWarning,
      StatusTone.error => colors.accentError,
    };
    final fallbackIcon = switch (tone) {
      StatusTone.info => Icons.info_outline_rounded,
      StatusTone.success => Icons.check_circle_outline_rounded,
      StatusTone.warning => Icons.warning_amber_rounded,
      StatusTone.error => Icons.error_outline_rounded,
    };
    return Semantics(
      liveRegion: true,
      label: message,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s12,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: colors.isDark ? .16 : .1),
          borderRadius: BorderRadius.circular(AppRadii.button),
        ),
        child: Row(
          children: [
            if (busy)
              SizedBox(
                width: AppSpacing.s16,
                height: AppSpacing.s16,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            else
              Icon(icon ?? fallbackIcon, size: 18, color: color),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Text(
                message,
                style: context.text.bodySmall?.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ),
            if (actionLabel != null)
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(foregroundColor: color),
                child: Text(actionLabel!),
              ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------------- composer

/// The spec's `ComposerBar`: the single text-entry surface for starting a
/// task or replying to one. Shows the active context above the field and a
/// stop button while a task is running.
class ComposerBar extends StatelessWidget {
  const ComposerBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.hint = 'Message your agent',
    this.enabled = true,
    this.sending = false,
    this.running = false,
    this.onStop,
    this.context,
    this.focusNode,
    this.autofocus = false,
    this.submitOnEnter = false,
  });

  final TextEditingController controller;
  final VoidCallback? onSend;
  final String hint;

  /// When true, the keyboard's action key sends instead of inserting a
  /// newline (single-line replies).
  final bool submitOnEnter;

  /// When false the field is read-only and the send button disabled — used
  /// while the user still has to pick a repository.
  final bool enabled;
  final bool sending;

  /// A task is executing: the send button becomes a stop button.
  final bool running;
  final VoidCallback? onStop;

  /// Usually a [ContextPill] showing the target repository.
  final Widget? context;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext buildContext) {
    final colors = buildContext.colors;
    final canSend = enabled && !sending && onSend != null;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: colors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (context != null) ...[
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.s4,
                bottom: AppSpacing.s8,
              ),
              child: context!,
            ),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  key: const Key('composer-field'),
                  controller: controller,
                  focusNode: focusNode,
                  autofocus: autofocus,
                  enabled: enabled,
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: submitOnEnter
                      ? TextInputAction.send
                      : TextInputAction.newline,
                  onSubmitted: submitOnEnter && canSend
                      ? (_) => onSend!()
                      : null,
                  style: buildContext.text.bodyLarge,
                  decoration: InputDecoration(
                    hintText: hint,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s12,
                      vertical: AppSpacing.s12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              if (running)
                IconButton.filled(
                  key: const Key('composer-stop'),
                  tooltip: 'Stop task',
                  onPressed: onStop,
                  style: IconButton.styleFrom(
                    backgroundColor: colors.accentError,
                    foregroundColor: colors.onAccent,
                    minimumSize: const Size(AppSpacing.s48, AppSpacing.s48),
                  ),
                  icon: const Icon(Icons.stop_rounded),
                )
              else
                IconButton.filled(
                  key: const Key('composer-send'),
                  tooltip: 'Send',
                  onPressed: canSend ? onSend : null,
                  style: IconButton.styleFrom(
                    backgroundColor: colors.accentPrimary,
                    foregroundColor: colors.onAccent,
                    disabledBackgroundColor: colors.accentPrimary.withValues(
                      alpha: .35,
                    ),
                    disabledForegroundColor: colors.onAccent,
                    minimumSize: const Size(AppSpacing.s48, AppSpacing.s48),
                  ),
                  icon: sending
                      ? SizedBox(
                          width: AppSpacing.s20,
                          height: AppSpacing.s20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: colors.onAccent,
                          ),
                        )
                      : const Icon(Icons.arrow_upward_rounded),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------- shells/sheets

/// A block of monospaced output (git status, command payloads, logs) on the
/// always-dark terminal surface.
class StitchTerminalBlock extends StatelessWidget {
  const StitchTerminalBlock({
    super.key,
    required this.text,
    this.maxLines,
    this.label,
  });

  final String text;
  final int? maxLines;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: colors.terminalBg,
        borderRadius: BorderRadius.circular(AppRadii.button),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Text(
              label!.toUpperCase(),
              style: context.text.labelSmall?.copyWith(
                color: colors.terminalMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
          ],
          Text(
            text,
            maxLines: maxLines,
            overflow: maxLines == null ? null : TextOverflow.ellipsis,
            style: AppTypography.code(color: colors.terminalText),
          ),
        ],
      ),
    );
  }
}

/// Opens a modal bottom sheet with the app's sheet chrome (rounded top,
/// drag handle, safe-area padding, keyboard avoidance).
Future<T?> showStitchSheet<T>(
  BuildContext context, {
  required Widget child,
  String? title,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.screen,
        right: AppSpacing.screen,
        top: AppSpacing.s8,
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + AppSpacing.s24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title, style: sheetContext.text.headlineSmall),
            const SizedBox(height: AppSpacing.s16),
          ],
          child,
        ],
      ),
    ),
  );
}

/// Prompts for an optional reason before rejecting an approval. Returns
/// `null` if the user cancelled (caller should not reject at all), or the
/// trimmed reason text (possibly empty, meaning "confirmed, no reason
/// given") if they pressed Reject.
Future<String?> showRejectReasonDialog(BuildContext context) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Reject this action?'),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLines: 3,
        decoration: const InputDecoration(
          hintText:
              'Reason (optional) — helps your agent try a better approach',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
          child: const Text('Reject'),
        ),
      ],
    ),
  );
}
