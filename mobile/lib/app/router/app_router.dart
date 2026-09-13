import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/app/router/page_transitions.dart';
import 'package:mobile/core/network/server_connection_controller.dart';
import 'package:mobile/features/account/presentation/account_screen.dart';
import 'package:mobile/features/account/presentation/sessions_screen.dart';
import 'package:mobile/features/ai_engine/presentation/ai_engine_screen.dart';
import 'package:mobile/features/approvals/presentation/approvals_screen.dart';
import 'package:mobile/features/home/presentation/home_screen.dart';
import 'package:mobile/features/home/presentation/recents_screen.dart';
import 'package:mobile/features/notifications/presentation/notifications_screen.dart';
import 'package:mobile/features/repos/presentation/repos_screen.dart';
import 'package:mobile/features/session/presentation/session_screen.dart';
import 'package:mobile/features/welcome/application/auth_controller.dart';
import 'package:mobile/features/welcome/application/onboarding_controller.dart';
import 'package:mobile/features/welcome/presentation/connect_desktop_screen.dart';
import 'package:mobile/features/welcome/presentation/first_repo_screen.dart';
import 'package:mobile/features/welcome/presentation/notifications_step_screen.dart';
import 'package:mobile/features/welcome/presentation/onboarding_nav.dart';
import 'package:mobile/features/welcome/presentation/qr_scan_screen.dart';
import 'package:mobile/features/welcome/presentation/runtime_choice_screen.dart';
import 'package:mobile/features/welcome/presentation/sign_in_screen.dart';
import 'package:mobile/features/welcome/presentation/splash_screen.dart';
import 'package:mobile/features/welcome/presentation/welcome_screen.dart';

/// Routes a signed-out user may visit: the pitch and everything needed to
/// get signed in. Anything else bounces to Welcome.
const _signedOutRoutes = {
  '/welcome',
  '/runtime',
  '/connect-desktop',
  '/scan',
  '/sign-in',
};

/// Detours the first-repo step may take (pairing a desktop so repos show
/// up) without counting as "leaving" onboarding.
const _repoStepDetours = {'/connect-desktop', '/scan', '/runtime'};

/// The single routing guard. Pure so it can be unit-tested without a
/// widget tree; [GoRouter.redirect] feeds it the live provider states.
///
/// Returns the location to redirect to, or null to allow [path] as is.
@visibleForTesting
String? resolveRedirect({
  required String path,
  required Map<String, String> query,
  required AsyncValue<bool> auth,
  required OnboardingState onboarding,
}) {
  // The very first auth state (session restore) has no value yet; every
  // later transition keeps the previous value, so "no value and no error"
  // is precisely "still bootstrapping".
  final bootstrapping =
      (!auth.hasValue && !auth.hasError) || !onboarding.isRestored;
  if (bootstrapping) return path == '/' ? null : '/';

  final signedIn = auth.value == true;
  if (!signedIn) return _signedOutRoutes.contains(path) ? null : '/welcome';

  final nextStep = onboarding.nextStepPath;
  if (nextStep != null) {
    if (path == nextStep) return null;
    if (nextStep == '/setup/repo' && _repoStepDetours.contains(path)) {
      return null;
    }
    return nextStep;
  }

  if (path == '/' ||
      path == '/welcome' ||
      path == '/sign-in' ||
      path.startsWith('/setup')) {
    return '/home';
  }
  if (path == '/runtime' && query['from'] != OnboardingFrom.account) {
    return '/home';
  }
  return null;
}

/// Bridges Riverpod state changes to go_router's [GoRouter.refreshListenable]
/// so the guard re-runs the moment auth, pairing, or onboarding changes.
class RouterRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = RouterRefreshNotifier();
  ref.onDispose(refresh.dispose);
  // Listening here also kicks off the auth restore at startup, which is
  // what the splash screen is waiting on.
  ref.listen(authControllerProvider, (_, _) => refresh.refresh());
  ref.listen(onboardingControllerProvider, (_, _) => refresh.refresh());
  ref.listen(serverUrlProvider, (_, _) => refresh.refresh());

  final router = GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) => resolveRedirect(
      path: state.uri.path,
      query: state.uri.queryParameters,
      auth: ref.read(authControllerProvider),
      onboarding: ref.read(onboardingControllerProvider),
    ),
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        pageBuilder: (context, state) =>
            fadeThroughPage(const SplashScreen(), state),
      ),
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        pageBuilder: (context, state) =>
            fadeThroughPage(const WelcomeScreen(), state),
      ),
      GoRoute(
        path: '/runtime',
        name: 'runtime',
        pageBuilder: (context, state) => fadeThroughPage(
          RuntimeChoiceScreen(from: state.uri.queryParameters['from']),
          state,
        ),
      ),
      GoRoute(
        path: '/connect-desktop',
        name: 'connect-desktop',
        pageBuilder: (context, state) => slideUpPage(
          ConnectDesktopScreen(from: state.uri.queryParameters['from']),
          state,
        ),
      ),
      GoRoute(
        path: '/scan',
        name: 'scan',
        pageBuilder: (context, state) =>
            slideUpPage(const QrScanScreen(), state),
      ),
      GoRoute(
        path: '/sign-in',
        name: 'sign-in',
        pageBuilder: (context, state) =>
            fadeThroughPage(const SignInScreen(), state),
      ),
      GoRoute(
        path: '/setup/repo',
        name: 'setup-repo',
        pageBuilder: (context, state) =>
            fadeThroughPage(const FirstRepoScreen(), state),
      ),
      GoRoute(
        path: '/setup/notifications',
        name: 'setup-notifications',
        pageBuilder: (context, state) =>
            fadeThroughPage(const NotificationsStepScreen(), state),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        pageBuilder: (context, state) =>
            fadeThroughPage(const HomeScreen(), state),
      ),
      GoRoute(
        path: '/session/:taskId',
        name: 'session',
        pageBuilder: (context, state) {
          final taskId = state.pathParameters['taskId']!;
          return slideUpPage(SessionScreen(taskId: taskId), state);
        },
      ),
      GoRoute(
        path: '/repos',
        name: 'repos',
        pageBuilder: (context, state) =>
            fadeThroughPage(const ReposScreen(), state),
      ),
      GoRoute(
        path: '/repos/:repoId',
        name: 'repo-detail',
        pageBuilder: (context, state) => slideUpPage(
          RepositoryDetailScreen(repoId: state.pathParameters['repoId']!),
          state,
        ),
      ),
      GoRoute(
        path: '/activity',
        name: 'activity',
        pageBuilder: (context, state) =>
            fadeThroughPage(const RecentsScreen(), state),
      ),
      GoRoute(
        path: '/approvals',
        name: 'approvals',
        pageBuilder: (context, state) =>
            slideUpPage(const ApprovalsScreen(), state),
      ),
      GoRoute(
        path: '/account',
        name: 'account',
        pageBuilder: (context, state) =>
            fadeThroughPage(const AccountScreen(), state),
      ),
      GoRoute(
        path: '/account/ai-engine',
        name: 'ai-engine',
        pageBuilder: (context, state) =>
            slideUpPage(const AiEngineScreen(), state),
      ),
      GoRoute(
        path: '/account/sessions',
        name: 'sessions',
        pageBuilder: (context, state) =>
            slideUpPage(const SessionsScreen(), state),
      ),
      GoRoute(
        path: '/account/notifications',
        name: 'notifications',
        pageBuilder: (context, state) =>
            slideUpPage(const NotificationsScreen(), state),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
