import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/features/account/application/sessions_controller.dart';
import 'package:mobile/shared/theme/theme.dart';
import 'package:mobile/shared/widgets/stitch_ui.dart';

class SessionsScreen extends ConsumerWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(sessionsProvider);
    return StitchScaffold(
      active: StitchTab.account,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, stitchDockClearance),
        children: [
          StitchHeader(
            title: 'Privacy & security',
            onBack: () => context.pop(),
          ),
          const SizedBox(height: 28),
          Text(
            'Signed-in sessions across your devices. Sign out of any you '
            "don't recognize.",
            style: TextStyle(color: context.colors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 24),
          value.when(
            data: (sessions) => _SessionsList(sessions: sessions),
            loading: () => const Padding(
              padding: EdgeInsets.only(top: 60),
              child: PhodexLoading(),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.only(top: 60),
              child: StitchErrorState(
                title: "Couldn't load your sessions",
                onRetry: () => ref.invalidate(sessionsProvider),
              ),
            ),
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
    final hasOthers = sessions.any((session) => !session.isCurrent);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final session in sessions) ...[
          _SessionTile(
            session: session,
            revoking: _revokingId == session.id,
            onRevoke: session.isCurrent ? null : () => _revoke(session.id),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 12),
        StitchPrimaryButton(
          label: _revokingOthers
              ? 'Signing out…'
              : 'Sign out of all other devices',
          onPressed: (!hasOthers || _revokingOthers) ? null : _revokeOthers,
        ),
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
    final dateFormat = DateFormat.yMMMd().add_jm();
    return StitchCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: session.isCurrent
                  ? context.colors.accentPrimarySoft
                  : context.colors.bgInput,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.devices_rounded,
              color: session.isCurrent
                  ? context.colors.accentPrimary
                  : context.colors.textMuted,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.isCurrent ? 'This device' : 'Other device',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Signed in ${dateFormat.format(session.createdAt.toLocal())}',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (onRevoke != null)
            revoking
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton(
                    onPressed: onRevoke,
                    child: Text(
                      'Sign out',
                      style: TextStyle(color: context.colors.accentError),
                    ),
                  ),
        ],
      ),
    );
  }
}
