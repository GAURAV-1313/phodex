import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/account/presentation/account_screen.dart';
import 'package:mobile/features/approvals/presentation/approvals_screen.dart';
import 'package:mobile/features/home/presentation/home_screen.dart';
import 'package:mobile/features/home/presentation/recents_screen.dart';
import 'package:mobile/features/repos/presentation/repos_screen.dart';
import 'package:mobile/features/session/presentation/session_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'recents',
            name: 'recents',
            builder: (context, state) => const RecentsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/session/:taskId',
        name: 'session',
        builder: (context, state) {
          final taskId = state.pathParameters['taskId']!;
          return SessionScreen(taskId: taskId);
        },
      ),
      GoRoute(
        path: '/repos',
        name: 'repos',
        builder: (context, state) => const ReposScreen(),
      ),
      GoRoute(
        path: '/approvals',
        name: 'approvals',
        builder: (context, state) => const ApprovalsScreen(),
      ),
      GoRoute(
        path: '/account',
        name: 'account',
        builder: (context, state) => const AccountScreen(),
      ),
    ],
  );
});
