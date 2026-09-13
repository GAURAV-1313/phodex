import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bump this when onboarding gains a step existing users must see; anyone
/// whose stored version is older is walked through whichever steps they
/// haven't completed yet.
const onboardingVersion = 1;

const onboardingVersionPrefsKey = 'phodex_onboarding_version';
const onboardingRepoStepPrefsKey = 'phodex_repo_step_done';
const onboardingNotificationsPrefsKey = 'phodex_notifications_prompted';

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, OnboardingState>(
      OnboardingController.new,
    );

/// What the router needs to know to send a signed-in user to the right
/// place: which post-sign-in steps are done, and whether the stored flags
/// have been read back from disk yet at all.
class OnboardingState {
  const OnboardingState({
    this.isRestored = false,
    this.version = 0,
    this.repoStepDone = false,
    this.notificationsPrompted = false,
  });

  /// False until SharedPreferences has been read once. The router keeps the
  /// splash up until then, so a returning user never flashes the welcome
  /// screen before their real state is known.
  final bool isRestored;
  final int version;
  final bool repoStepDone;
  final bool notificationsPrompted;

  /// Onboarding has been finished for the current [onboardingVersion] — or
  /// every step it contains is done, which is the same thing in practice
  /// even if the version stamp hasn't landed yet.
  bool get isComplete =>
      version >= onboardingVersion || (repoStepDone && notificationsPrompted);

  /// The route of the first step still to do, or null when all are done.
  String? get nextStepPath {
    if (isComplete) return null;
    if (!repoStepDone) return '/setup/repo';
    if (!notificationsPrompted) return '/setup/notifications';
    return null;
  }

  OnboardingState copyWith({
    bool? isRestored,
    int? version,
    bool? repoStepDone,
    bool? notificationsPrompted,
  }) => OnboardingState(
    isRestored: isRestored ?? this.isRestored,
    version: version ?? this.version,
    repoStepDone: repoStepDone ?? this.repoStepDone,
    notificationsPrompted: notificationsPrompted ?? this.notificationsPrompted,
  );
}

/// Persists onboarding progress so the app can resume at the right step
/// after a restart, and re-run the whole thing after sign-out. Restores
/// asynchronously in the same "restore, don't block" shape as
/// `ThemeModeController` — but exposes [OnboardingState.isRestored] so the
/// router can tell "not done yet" apart from "not loaded yet".
class OnboardingController extends Notifier<OnboardingState> {
  @override
  OnboardingState build() {
    _restore();
    return const OnboardingState();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = OnboardingState(
        isRestored: true,
        version: prefs.getInt(onboardingVersionPrefsKey) ?? 0,
        repoStepDone: prefs.getBool(onboardingRepoStepPrefsKey) ?? false,
        notificationsPrompted:
            prefs.getBool(onboardingNotificationsPrefsKey) ?? false,
      );
    } catch (_) {
      // Preferences being unreadable must never strand the app on the
      // splash screen — fall back to "fresh install" and carry on.
      state = const OnboardingState(isRestored: true);
    }
  }

  bool get isRestored => state.isRestored;
  bool get repoStepDone => state.repoStepDone;
  bool get notificationsPrompted => state.notificationsPrompted;
  bool get isComplete => state.isComplete;

  Future<void> markRepoStepDone() async {
    state = state.copyWith(repoStepDone: true);
    await _persistBool(onboardingRepoStepPrefsKey, true);
  }

  Future<void> markNotificationsPrompted() async {
    state = state.copyWith(notificationsPrompted: true);
    await _persistBool(onboardingNotificationsPrefsKey, true);
  }

  /// Stamps the current version: every step is done and the user goes
  /// straight to Home from now on.
  Future<void> complete() async {
    state = state.copyWith(
      version: onboardingVersion,
      repoStepDone: true,
      notificationsPrompted: true,
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(onboardingVersionPrefsKey, onboardingVersion);
      await prefs.setBool(onboardingRepoStepPrefsKey, true);
      await prefs.setBool(onboardingNotificationsPrefsKey, true);
    } catch (_) {
      // Best-effort persistence; in-memory state is already updated.
    }
  }

  /// Called on sign-out so the next sign-in walks through setup again
  /// (a different account may need a different repository).
  Future<void> reset() async {
    state = const OnboardingState(isRestored: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(onboardingVersionPrefsKey);
      await prefs.remove(onboardingRepoStepPrefsKey);
      await prefs.remove(onboardingNotificationsPrefsKey);
    } catch (_) {
      // Best-effort persistence; in-memory state is already updated.
    }
  }

  Future<void> _persistBool(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (_) {
      // Best-effort persistence; in-memory state is already updated.
    }
  }
}
