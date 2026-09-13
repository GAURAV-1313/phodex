import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Back for onboarding screens: pop when there is somewhere to pop to,
/// otherwise jump to [fallback] — a screen reached by deep link or a
/// redirect has no stack beneath it, and a bare `pop()` would throw.
void popOrGo(BuildContext context, String fallback) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(fallback);
  }
}

/// Values of the `?from=` query parameter the setup screens understand.
/// They decide whether "Continue"/"Done" moves onboarding forward or simply
/// returns to wherever the user came from.
abstract final class OnboardingFrom {
  static const account = 'account';
  static const setup = 'setup';
}
