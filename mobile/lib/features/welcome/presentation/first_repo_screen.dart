import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/core/providers/repository_providers.dart';
import 'package:mobile/features/repos/application/repos_controller.dart';
import 'package:mobile/features/welcome/application/onboarding_controller.dart';
import 'package:mobile/features/welcome/presentation/onboarding_nav.dart';
import 'package:mobile/shared/theme/theme.dart';
import 'package:mobile/shared/widgets/phodex_mascot.dart';
import 'package:mobile/shared/widgets/stagger_in.dart';
import 'package:mobile/shared/widgets/stitch_ui.dart';

/// A fresh read of the runtime for this step only. The app-wide
/// `runtimeInfoProvider` is cached for the session, but the runtime may
/// have changed since it last resolved (sign out, switch runtime, sign back
/// in) — cloud-vs-desktop here must never come from a stale answer.
final _stepRuntimeProvider = FutureProvider.autoDispose<RuntimeInfo>((ref) {
  return ref.watch(runtimeRepositoryProvider).getRuntimeInfo();
});

/// The repositories a paired desktop has synced so far. Local to this
/// screen (and auto-disposed) so returning from a pairing detour always
/// re-fetches instead of showing the list from before pairing.
final _syncedRepositoriesProvider =
    FutureProvider.autoDispose<List<SyncedRepository>>((ref) {
      return ref.watch(repoRepositoryProvider).listRepositories();
    });

/// Onboarding step two: give the agent something to work on. On Phodex
/// Cloud that means connecting a GitHub repository; on a paired desktop it
/// means picking one the device agent already synced. Either way the step
/// can be skipped — Home offers the same choice later.
class FirstRepoScreen extends ConsumerWidget {
  const FirstRepoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runtime = ref.watch(_stepRuntimeProvider);
    return StitchScaffold(
      key: const Key('first-repo-screen'),
      showDock: false,
      child: ListView(
        padding: stitchScreenPaddingNoDock,
        children: [
          const StitchHeader(
            title: 'Your first repo',
            mood: MascotMood.curious,
          ),
          const SizedBox(height: AppSpacing.s24),
          StitchAsyncView<RuntimeInfo>(
            value: runtime,
            errorTitle: "Couldn't reach your runtime",
            errorMessage: 'Check that it is online, then try again.',
            onRetry: () => ref.invalidate(_stepRuntimeProvider),
            builder: (context, info) => info.isCloud
                ? const _CloudRepoForm()
                : const _DesktopRepoList(),
          ),
        ],
      ),
    );
  }
}

/// Marks the step done and moves on. Shared by every way out of this
/// screen: connect, pick, or skip.
Future<void> _finishRepoStep(BuildContext context, WidgetRef ref) async {
  await ref.read(onboardingControllerProvider.notifier).markRepoStepDone();
  if (context.mounted) context.go('/setup/notifications');
}

Widget _skipButton(BuildContext context, WidgetRef ref, {bool enabled = true}) {
  return StitchSecondaryButton(
    key: const Key('first-repo-skip'),
    label: 'Skip for now',
    onPressed: enabled ? () => _finishRepoStep(context, ref) : null,
  );
}

// ------------------------------------------------------------------ cloud

class _CloudRepoForm extends ConsumerStatefulWidget {
  const _CloudRepoForm();

  @override
  ConsumerState<_CloudRepoForm> createState() => _CloudRepoFormState();
}

class _CloudRepoFormState extends ConsumerState<_CloudRepoForm> {
  final _url = TextEditingController();
  final _branch = TextEditingController();
  final _token = TextEditingController();
  bool _connecting = false;
  String? _error;

  @override
  void dispose() {
    _url.dispose();
    _branch.dispose();
    _token.dispose();
    super.dispose();
  }

  /// Accepts `https://github.com/owner/repo(.git)` and the same without a
  /// scheme; anything else is rejected before a request is made.
  static String? _normalizeGithubUrl(String raw) {
    var input = raw.trim();
    if (input.isEmpty) return null;
    if (!input.contains('://')) input = 'https://$input';
    final uri = Uri.tryParse(input);
    if (uri == null || !uri.host.toLowerCase().endsWith('github.com')) {
      return null;
    }
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length < 2) return null;
    return uri.toString();
  }

  Future<void> _connect() async {
    final url = _normalizeGithubUrl(_url.text);
    if (url == null) {
      setState(
        () => _error =
            'Enter a GitHub repository URL, like '
            'https://github.com/owner/repo',
      );
      return;
    }
    setState(() {
      _connecting = true;
      _error = null;
    });
    try {
      final repos = ref.read(repoRepositoryProvider);
      final branch = _branch.text.trim();
      final token = _token.text.trim();
      final repo = await repos.connectGithubRepository(
        url: url,
        branch: branch.isEmpty ? null : branch,
        token: token.isEmpty ? null : token,
      );
      await repos.selectRepository(repoId: repo.id);
      // Home reads its context through this provider; make sure it can't
      // hold on to whatever was selected before this sign-in.
      ref.invalidate(selectedProjectContextProvider);
      if (!mounted) return;
      await _finishRepoStep(context, ref);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error =
            "Couldn't connect that repository. Check the URL (and the "
            'token, for private repos), then try again.',
      );
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Phodex Cloud clones a GitHub repository onto its runner and '
          'works there. Public repos need no token.',
          style: context.text.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.s20),
        TextField(
          key: const Key('first-repo-url'),
          controller: _url,
          keyboardType: TextInputType.url,
          autocorrect: false,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'GitHub repository URL',
            hintText: 'https://github.com/owner/repo',
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        TextField(
          key: const Key('first-repo-branch'),
          controller: _branch,
          autocorrect: false,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Branch (optional)',
            hintText: 'main',
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        TextField(
          key: const Key('first-repo-token'),
          controller: _token,
          obscureText: true,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _connecting ? null : _connect(),
          decoration: const InputDecoration(
            labelText: 'GitHub token (optional)',
            hintText: 'github_pat_…',
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          'For private repos, use a fine-grained personal access token '
          'scoped to just this repository with Contents read & write. '
          "It's stored encrypted on your runtime, never on this phone.",
          style: context.text.bodySmall?.copyWith(
            color: context.colors.textMuted,
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.s16),
          StatusBanner(message: _error!, tone: StatusTone.error),
        ],
        const SizedBox(height: AppSpacing.s24),
        StitchPrimaryButton(
          key: const Key('first-repo-connect'),
          label: 'Connect repository',
          icon: Icons.link_rounded,
          loading: _connecting,
          onPressed: _connect,
        ),
        const SizedBox(height: AppSpacing.s12),
        _skipButton(context, ref, enabled: !_connecting),
      ],
    );
  }
}

// ---------------------------------------------------------------- desktop

class _DesktopRepoList extends ConsumerStatefulWidget {
  const _DesktopRepoList();

  @override
  ConsumerState<_DesktopRepoList> createState() => _DesktopRepoListState();
}

class _DesktopRepoListState extends ConsumerState<_DesktopRepoList> {
  String? _selectingId;
  String? _error;

  Future<void> _select(SyncedRepository repo) async {
    setState(() {
      _selectingId = repo.id;
      _error = null;
    });
    try {
      await ref.read(repoRepositoryProvider).selectRepository(repoId: repo.id);
      ref.invalidate(selectedProjectContextProvider);
      if (!mounted) return;
      await _finishRepoStep(context, ref);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = "Couldn't select that repository. Try again.");
    } finally {
      if (mounted) setState(() => _selectingId = null);
    }
  }

  Future<void> _backToPairing() async {
    await context.push<bool>('/connect-desktop?from=${OnboardingFrom.setup}');
    ref.invalidate(_syncedRepositoriesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final repos = ref.watch(_syncedRepositoriesProvider);
    return StitchAsyncView<List<SyncedRepository>>(
      value: repos,
      errorTitle: "Couldn't load your repos",
      onRetry: () => ref.invalidate(_syncedRepositoriesProvider),
      isEmpty: (list) => list.isEmpty,
      empty: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.s24),
        child: StitchEmptyState(
          mood: MascotMood.curious,
          title: 'No repos synced yet',
          message:
              'Run the Phodex device agent on your desktop to sync your '
              'projects.',
          actionLabel: 'Back to pairing',
          onAction: _backToPairing,
          secondaryActionLabel: 'Skip for now',
          onSecondaryAction: () => _finishRepoStep(context, ref),
        ),
      ),
      builder: (context, list) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'These repos are synced from your desktop. Pick the one your '
            'agent should start in.',
            style: context.text.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.s20),
          if (_error != null) ...[
            StatusBanner(message: _error!, tone: StatusTone.error),
            const SizedBox(height: AppSpacing.s16),
          ],
          for (final (index, repo) in list.indexed) ...[
            StaggerIn(
              index: index,
              child: _RepoCard(
                repo: repo,
                selecting: _selectingId == repo.id,
                onTap: _selectingId == null ? () => _select(repo) : null,
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
          ],
          const SizedBox(height: AppSpacing.s8),
          _skipButton(context, ref, enabled: _selectingId == null),
        ],
      ),
    );
  }
}

class _RepoCard extends StatelessWidget {
  const _RepoCard({
    required this.repo,
    required this.selecting,
    required this.onTap,
  });

  final SyncedRepository repo;
  final bool selecting;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final branch = repo.currentBranch ?? repo.defaultBranch ?? 'main';
    return Semantics(
      button: true,
      label: 'Repository ${repo.name} on $branch, from ${repo.deviceName}',
      child: StitchCard(
        key: Key('first-repo-${repo.id}'),
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Row(
          children: [
            Container(
              width: AppSpacing.s40,
              height: AppSpacing.s40,
              decoration: BoxDecoration(
                color: colors.bgInput,
                borderRadius: BorderRadius.circular(AppRadii.chip),
              ),
              child: Icon(
                Icons.folder_outlined,
                size: 20,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(repo.name, style: context.text.titleMedium),
                  const SizedBox(height: AppSpacing.s2),
                  Text(
                    '${repo.deviceName} · $branch',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            if (selecting)
              const SizedBox(
                width: AppSpacing.s20,
                height: AppSpacing.s20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(Icons.chevron_right_rounded, color: colors.textMuted),
          ],
        ),
      ),
    );
  }
}
