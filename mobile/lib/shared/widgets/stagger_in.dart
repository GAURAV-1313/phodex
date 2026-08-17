import 'package:flutter/material.dart';

/// Wraps a list item so it fades and slides in shortly after its
/// predecessor, instead of the whole list appearing at once. Used for every
/// card list in the app (tasks, repos, approvals) so new content always
/// feels like it's arriving, not just snapping into place.
class StaggerIn extends StatefulWidget {
  const StaggerIn({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<StaggerIn> createState() => _StaggerInState();
}

class _StaggerInState extends State<StaggerIn> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    final delayMs = 35 * widget.index.clamp(0, 8);
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.05),
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
