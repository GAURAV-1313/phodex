import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/app/router/page_transitions.dart';
import 'package:mobile/features/account/presentation/account_screen.dart';
import 'package:mobile/features/ai_engine/presentation/ai_engine_screen.dart';
import 'package:mobile/features/approvals/presentation/approvals_screen.dart';
import 'package:mobile/features/home/presentation/home_screen.dart';
import 'package:mobile/features/home/presentation/recents_screen.dart';
import 'package:mobile/features/account/presentation/sessions_screen.dart';
import 'package:mobile/features/notifications/presentation/notifications_screen.dart';
import 'package:mobile/features/repos/presentation/repos_screen.dart';
import 'package:mobile/features/session/presentation/session_screen.dart';
import 'package:mobile/features/welcome/presentation/connect_desktop_screen.dart';
import 'package:mobile/features/welcome/presentation/welcome_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/welcome',
    routes: [
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        pageBuilder: (context, state) =>
            fadeThroughPage(const WelcomeScreen(), state),
      ),
      GoRoute(
        path: '/connect-desktop',
        name: 'connect-desktop',
        pageBuilder: (context, state) =>
            slideUpPage(const ConnectDesktopScreen(), state),
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
});
