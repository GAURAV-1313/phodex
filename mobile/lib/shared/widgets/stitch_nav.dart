import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Leaves a pushed screen the way the user expects: pop back to wherever
/// they came from when there is somewhere to go, otherwise (deep link,
/// notification tap, nothing underneath) jump to [fallback]. Screens that
/// are pushed must never `go()` to a tab on "back"/"done" — that would wipe
/// out the stack the user built up.
void stitchPopOrGo(BuildContext context, String fallback) {
  final router = GoRouter.maybeOf(context);
  if (router == null) {
    // No router (widget tests, previews): fall back to the plain navigator.
    Navigator.of(context).maybePop();
    return;
  }
  if (router.canPop()) {
    router.pop();
  } else {
    router.go(fallback);
  }
}
