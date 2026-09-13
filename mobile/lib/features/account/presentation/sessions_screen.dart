import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/features/account/application/sessions_controller.dart';
import 'package:mobile/shared/theme/theme.dart';
import 'package:mobile/shared/widgets/phodex_mascot.dart';
import 'package:mobile/shared/widgets/stitch_ui.dart';

class SessionsScreen extends ConsumerWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(sessionsProvider);
    return StitchScaffold(
      key: const Key('sessions-screen'),
      active: StitchTab.account,
      child: ListView(
        padding: stitchScreenPadding,
        children: [
          StitchHeader(
            title: 'Privacy & security',
            onBack: () => context.pop(),
          ),
          const SizedBox(height: AppSpacing.s24),
          Text(
            'Signed-in sessions across your devices. Sign out of any you '
            "don't recognize.",
            style: context.text.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.s24),
          StitchAsyncView<List<SessionInfo>>(
            value: value,
            errorTitle: "Couldn't load your sessions",
            onRetry: () => ref.invalidate(sessionsProvider),
            builder: (context, sessions) => _SessionsList(sessions: sessions),
          ),
        ],
      ),
    );
  }
}

class _SessionsList extends ConsumerStatefulWidget {
  const _SessionsList({required this.sessions});
  final List<SessionInfo> sessions;

  @override
  ConsumerState<_SessionsList> createState() => _SessionsListState();
}

class _SessionsListState extends ConsumerState<_SessionsList> {
  String? _revokingId;
  bool _revokingOthers = false;

  Future<void> _revoke(String sessionId) async {
    setState(() => _revokingId = sessionId);
    try {
      await ref.read(sessionsProvider.notifier).revoke(sessionId);
    } finally {
      if (mounted) setState(() => _revokingId = null);
    }
  }

  Future<void> _revokeOthers() async {
    setState(() => _revokingOthers = true);
    try {
      final count = await ref.read(sessionsProvider.notifier).revokeOthers();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count == 0
                ? 'No other sessions to sign out of'
                : 'Signed out of $count other session${count == 1 ? '' : 's'}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _revokingOthers = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessions = widget.sessions;
    final current = sessions.where((session) => session.isCurrent).toList();
    final others = sessions.where((session) => !session.isCurrent).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final session in current) ...[
          _SessionTile(session: session, revoking: false, onRevoke: null),
          const SizedBox(height: AppSpacing.s12),
        ],
        if (others.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.s24),
            child: StitchEmptyState(
              mood: MascotMood.resting,
              title: 'No other sessions',
              message: "You're only signed in on this device.",
            ),
          )
        else ...[
          for (final session in others) ...[
            _SessionTile(
              session: session,
              revoking: _revokingId == session.id,
              onRevoke: () => _revoke(session.id),
            ),
            const SizedBox(height: AppSpacing.s12),
          ],
          const SizedBox(height: AppSpacing.s12),
          StitchPrimaryButton(
            label: _revokingOthers
                ? 'Signing out…'
                : 'Sign out of all other devices',
            loading: _revokingOthers,
            onPressed: _revokeOthers,
          ),
        ],
      ],
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.session,
    required this.revoking,
    required this.onRevoke,
  });

  final SessionInfo session;
  final bool revoking;
  final VoidCallback? onRevoke;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dateFormat = DateFormat.yMMMd().add_jm();
    return StitchCard(
      child: Row(
        children: [
          Container(
            width: AppSpacing.s40,
            height: AppSpacing.s40,
            decoration: BoxDecoration(
              color: session.isCurrent
                  ? colors.accentPrimarySoft
                  : colors.bgInput,
              borderRadius: BorderRadius.circular(AppRadii.chip),
            ),
            child: Icon(
              Icons.devices_rounded,
              size: 20,
              color: session.isCurrent
                  ? colors.accentPrimary
                  : colors.textMuted,
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.isCurrent ? 'This device' : 'Other device',
                  style: context.text.titleMedium,
                ),
                const SizedBox(height: AppSpacing.s2),
                Text(
                  'Signed in ${dateFormat.format(session.createdAt.toLocal())}',
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
          if (onRevoke != null)
            revoking
                ? const SizedBox(
                    width: AppSpacing.s20,
                    height: AppSpacing.s20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton(
                    onPressed: onRevoke,
                    child: Text(
                      'Sign out',
                      style: context.text.labelLarge?.copyWith(
                        color: colors.accentError,
                      ),
                    ),
                  ),
        ],
      ),
    );
  }
}
