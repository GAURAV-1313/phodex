import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/welcome/application/onboarding_controller.dart';
import 'package:mobile/features/welcome/application/phodex_address.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The controller restores from (mocked) SharedPreferences asynchronously;
/// give that a few event-loop turns rather than assuming exactly one.
Future<void> untilRestored(ProviderContainer container) async {
  for (var i = 0; i < 20; i++) {
    if (container.read(onboardingControllerProvider).isRestored) return;
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  fail('OnboardingController never restored');
}

void main() {
  group('OnboardingController', () {
    test('starts un-restored, then restores stored flags', () async {
      SharedPreferences.setMockInitialValues({
        onboardingRepoStepPrefsKey: true,
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(onboardingControllerProvider).isRestored, isFalse);
      await untilRestored(container);

      final state = container.read(onboardingControllerProvider);
      expect(state.isRestored, isTrue);
      expect(state.repoStepDone, isTrue);
      expect(state.notificationsPrompted, isFalse);
      expect(state.isComplete, isFalse);
      expect(state.nextStepPath, '/setup/notifications');
    });

    test('complete() stamps the version and persists every flag', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(onboardingControllerProvider.notifier);
      await untilRestored(container);

      await controller.markRepoStepDone();
      await controller.markNotificationsPrompted();
      await controller.complete();

      final state = container.read(onboardingControllerProvider);
      expect(state.isComplete, isTrue);
      expect(state.nextStepPath, isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(onboardingVersionPrefsKey), onboardingVersion);
      expect(prefs.getBool(onboardingRepoStepPrefsKey), isTrue);
      expect(prefs.getBool(onboardingNotificationsPrefsKey), isTrue);
    });

    test('reset() clears everything so onboarding runs again', () async {
      SharedPreferences.setMockInitialValues({
        onboardingVersionPrefsKey: onboardingVersion,
        onboardingRepoStepPrefsKey: true,
        onboardingNotificationsPrefsKey: true,
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await untilRestored(container);
      expect(container.read(onboardingControllerProvider).isComplete, isTrue);

      await container.read(onboardingControllerProvider.notifier).reset();

      final state = container.read(onboardingControllerProvider);
      expect(state.isRestored, isTrue);
      expect(state.isComplete, isFalse);
      expect(state.nextStepPath, '/setup/repo');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(onboardingVersionPrefsKey), isNull);
    });
  });

  group('parsePhodexAddress', () {
    test('accepts absolute http/https URLs with a host', () {
      expect(
        parsePhodexAddress('http://100.64.0.3:8000'),
        'http://100.64.0.3:8000',
      );
      expect(
        parsePhodexAddress('  https://phodex.tail1234.ts.net/ '),
        'https://phodex.tail1234.ts.net/',
      );
    });

    test('rejects anything that is not a server address', () {
      expect(parsePhodexAddress(''), isNull);
      expect(parsePhodexAddress('hello world'), isNull);
      expect(parsePhodexAddress('192.168.1.10:8000'), isNull);
      expect(parsePhodexAddress('mailto:someone@example.com'), isNull);
      expect(parsePhodexAddress('ftp://files.example.com'), isNull);
      expect(parsePhodexAddress('http://'), isNull);
    });
  });
}
