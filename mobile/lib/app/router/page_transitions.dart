import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A soft cross-fade + scale — used for top-level tab-style destinations
/// (Home, Tasks, Repos, Account) where screens feel like siblings, not a
/// hierarchy, so a slide would misleadingly imply "going deeper."
CustomTransitionPage<void> fadeThroughPage(
  Widget child,
  GoRouterState state,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween(begin: 0.985, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// A gentle upward slide + fade — used for detail/push destinations
/// (Session, Repository detail, Approvals) that read as "going deeper" into
/// something the user tapped.
CustomTransitionPage<void> slideUpPage(Widget child, GoRouterState state) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.05),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
