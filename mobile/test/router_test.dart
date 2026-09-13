import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/router/app_router.dart';
import 'package:mobile/features/welcome/application/auth_controller.dart';
import 'package:mobile/features/welcome/application/onboarding_controller.dart';
import 'package:mobile/features/welcome/presentation/first_repo_screen.dart';
import 'package:mobile/features/welcome/presentation/notifications_step_screen.dart';
import 'package:mobile/features/welcome/presentation/welcome_screen.dart';

import 'test_helpers.dart';

void main() {
  group('resolveRedirect (pure guard)', () {
    const restoredFresh = OnboardingState(isRestored: true);
    const complete = OnboardingState(
      isRestored: true,
      version: onboardingVersion,
      repoStepDone: true,
      notificationsPrompted: true,
    );
    String? redirect(
      String path, {
      AsyncValue<bool> auth = const AsyncData(false),
      OnboardingState onboarding = restoredFresh,
      Map<String, String> query = const {},
    }) => resolveRedirect(
      path: path,
      query: query,
      auth: auth,
      onboarding: onboarding,
    );

    test('holds the splash while auth or onboarding is still loading', () {
      expect(redirect('/', auth: const AsyncLoading()), isNull);
      expect(redirect('/home', auth: const AsyncLoading()), '/');
      expect(redirect('/welcome', onboarding: const OnboardingState()), '/');
    });

    test('a sign-in in flight (previous value kept) is not bootstrapping', () {
      final inFlight = const AsyncLoading<bool>().copyWithPrevious(
        const AsyncData(false),
      );
      expect(redirect('/sign-in', auth: inFlight), isNull);
    });

    test('signed out: only the onboarding entry routes are reachable', () {
      for (final path in [
        '/welcome',
        '/runtime',
        '/connect-desktop',
        '/scan',
        '/sign-in',
      ]) {
        expect(redirect(path), isNull, reason: path);
      }
      expect(redirect('/'), '/welcome');
      expect(redirect('/home'), '/welcome');
      expect(redirect('/setup/repo'), '/welcome');
      expect(redirect('/account'), '/welcome');
    });

    test('signed in with onboarding incomplete lands on the next step', () {
      const signedIn = AsyncData(true);
      expect(redirect('/home', auth: signedIn), '/setup/repo');
      expect(redirect('/setup/repo', auth: signedIn), isNull);
      // Pairing a desktop is a legitimate detour from the repo step.
      expect(redirect('/connect-desktop', auth: signedIn), isNull);
      expect(redirect('/scan', auth: signedIn), isNull);

      const repoDone = OnboardingState(isRestored: true, repoStepDone: true);
      expect(
        redirect('/setup/repo', auth: signedIn, onboarding: repoDone),
        '/setup/notifications',
      );
      expect(
        redirect('/home', auth: signedIn, onboarding: repoDone),
        '/setup/notifications',
      );
      expect(
        redirect('/setup/notifications', auth: signedIn, onboarding: repoDone),
        isNull,
      );
    });

    test('signed in and complete: onboarding routes collapse to home', () {
      const signedIn = AsyncData(true);
      for (final path in [
        '/',
        '/welcome',
        '/sign-in',
        '/setup/repo',
        '/setup/notifications',
        '/runtime',
      ]) {
        expect(
          redirect(path, auth: signedIn, onboarding: complete),
          '/home',
          reason: path,
        );
      }
      expect(
        redirect(
          '/runtime',
          auth: signedIn,
          onboarding: complete,
          query: const {'from': 'account'},
        ),
        isNull,
      );
      for (final path in [
        '/home',
        '/account',
        '/connect-desktop',
        '/session/task_1',
        '/repos',
      ]) {
        expect(
          redirect(path, auth: signedIn, onboarding: complete),
          isNull,
          reason: path,
        );
      }
    });
  });

  group('app router', () {
    testWidgets('cold start lands on Welcome when not signed in', (
      tester,
    ) async {
      final container = await pumpPhodexApp(tester);

      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(container.read(appRouterProvider).state.uri.path, '/welcome');
    });

    testWidgets('a deep link to /home while signed out bounces to Welcome', (
      tester,
    ) async {
      final container = await pumpPhodexApp(tester);

      container.read(appRouterProvider).go('/home');
      await settle(tester);

      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.byKey(const Key('home-screen')), findsNothing);
      expect(container.read(appRouterProvider).state.uri.path, '/welcome');
    });

    testWidgets('signed in with onboarding complete goes straight to Home', (
      tester,
    ) async {
      final container = await pumpPhodexApp(
        tester,
        signedIn: true,
        onboardingComplete: true,
      );

      expect(find.byKey(const Key('home-screen')), findsOneWidget);
      expect(container.read(appRouterProvider).state.uri.path, '/home');
    });

    testWidgets('signed in with the repo step incomplete goes to /setup/repo', (
      tester,
    ) async {
      final container = await pumpPhodexApp(tester, signedIn: true);

      expect(find.byType(FirstRepoScreen), findsOneWidget);
      expect(container.read(appRouterProvider).state.uri.path, '/setup/repo');
    });

    testWidgets('finishing the repo step moves on to the notifications step', (
      tester,
    ) async {
      final container = await pumpPhodexApp(tester, signedIn: true);

      await container
          .read(onboardingControllerProvider.notifier)
          .markRepoStepDone();
      await settle(tester);

      expect(find.byType(NotificationsStepScreen), findsOneWidget);
    });

    testWidgets('signing out returns to Welcome', (tester) async {
      final container = await pumpPhodexApp(
        tester,
        signedIn: true,
        onboardingComplete: true,
      );
      expect(find.byKey(const Key('home-screen')), findsOneWidget);

      await container.read(authControllerProvider.notifier).signOut();
      await settle(tester);

      expect(find.byType(WelcomeScreen), findsOneWidget);
    });
  });
}
