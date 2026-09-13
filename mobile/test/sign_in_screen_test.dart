import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/router/app_router.dart';
import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/features/welcome/application/auth_controller.dart';
import 'package:mobile/features/welcome/presentation/first_repo_screen.dart';
import 'package:mobile/features/welcome/presentation/sign_in_screen.dart';

import 'test_helpers.dart';

/// Stands in for a sign-in attempt that failed for a known reason, so the
/// screen's error copy can be checked without a Google SDK in the loop.
class _FailedAuthController extends AuthController {
  _FailedAuthController(this.error);
  final Object error;

  @override
  Future<bool> build() async => throw error;
}

void main() {
  group('AuthFailure.fromError', () {
    test('classifies the errors the sign-in flow can produce', () {
      expect(
        AuthFailure.fromError(StateError('Google sign-in was cancelled.')),
        AuthFailure.cancelled,
      );
      expect(
        AuthFailure.fromError(UnsupportedError('no SDK button')),
        AuthFailure.unsupportedPlatform,
      );
      expect(
        AuthFailure.fromError(
          DioException(
            requestOptions: RequestOptions(),
            type: DioExceptionType.connectionTimeout,
          ),
        ),
        AuthFailure.runtimeUnreachable,
      );
      expect(
        AuthFailure.fromError(
          DioException(
            requestOptions: RequestOptions(),
            type: DioExceptionType.connectionError,
          ),
        ),
        AuthFailure.runtimeUnreachable,
      );
      expect(
        AuthFailure.fromError(
          DioException(
            requestOptions: RequestOptions(),
            type: DioExceptionType.unknown,
          ),
        ),
        AuthFailure.noNetwork,
      );
      expect(
        AuthFailure.fromError(
          DioException(
            requestOptions: RequestOptions(),
            type: DioExceptionType.badResponse,
          ),
        ),
        AuthFailure.unknown,
      );
      expect(
        AuthFailure.fromError(TimeoutException('token')),
        AuthFailure.cancelled,
      );
      expect(AuthFailure.fromError(Exception('?')), AuthFailure.unknown);
    });
  });

  testWidgets('Shows the Google button and no demo on a desktop runtime', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapWithTestApp(const SignInScreen(), runtimeMode: RuntimeMode.desktop),
    );
    await settle(tester);

    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Try the demo'), findsNothing);
    expect(find.text('Change'), findsOneWidget);
  });

  testWidgets('Offers the demo account when the runtime is Phodex Cloud', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapWithTestApp(const SignInScreen(), runtimeMode: RuntimeMode.cloud),
    );
    await settle(tester);

    expect(find.text('Try the demo'), findsOneWidget);

    await tester.tap(find.text('Try the demo'));
    await settle(tester);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(SignInScreen)),
    );
    expect(container.read(authControllerProvider).value, isTrue);
  });

  testWidgets('A cancelled sign-in says so, specifically', (tester) async {
    await tester.pumpWidget(
      wrapWithTestApp(
        const SignInScreen(),
        overrides: [
          authControllerProvider.overrideWith(
            () => _FailedAuthController(
              StateError('Google sign-in was cancelled.'),
            ),
          ),
        ],
      ),
    );
    await settle(tester);

    expect(find.text('Sign-in was cancelled.'), findsOneWidget);
    expect(find.text('Change runtime'), findsNothing);
  });

  testWidgets('An unreachable runtime offers to change it', (tester) async {
    await tester.pumpWidget(
      wrapWithTestApp(
        const SignInScreen(),
        overrides: [
          authControllerProvider.overrideWith(
            () => _FailedAuthController(
              DioException(
                requestOptions: RequestOptions(),
                type: DioExceptionType.connectionError,
              ),
            ),
          ),
        ],
      ),
    );
    await settle(tester);

    expect(
      find.text(
        "Couldn't reach your runtime. Check that it's online, then try again.",
      ),
      findsOneWidget,
    );
    expect(find.text('Change runtime'), findsOneWidget);
  });

  testWidgets('Continue with Google signs in and the guard moves on', (
    tester,
  ) async {
    final container = await pumpPhodexApp(tester);
    container.read(appRouterProvider).go('/sign-in');
    await settle(tester);
    expect(find.byType(SignInScreen), findsOneWidget);

    await tester.tap(find.byKey(const Key('sign-in-google')));
    await settle(tester);

    expect(container.read(authControllerProvider).value, isTrue);
    expect(find.byType(FirstRepoScreen), findsOneWidget);
  });
}
