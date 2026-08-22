import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mobile/core/domain/models/models.dart';

import '../theme/app_colors.dart';

/// The states the mascot can actually communicate — each one is driven by a
/// real backend task state, not a decorative variant with no meaning behind
/// it.
enum MascotMood {
  /// Connected, nothing running — home screen at rest.
  idle,

  /// A task is queued, starting, or actively running.
  thinking,

  /// A task is waiting on the user — an approval, specifically, not "busy."
  curious,

  /// Task completed successfully.
  success,

  /// Task failed, or the backend connection is down.
  error,

  /// Task was cancelled — deliberately stopped, not a failure. Calm, not sad.
  resting,
}

/// The single source of truth for mapping a task's real backend status to a
/// mascot expression — used anywhere a task's state needs a face.
MascotMood moodForTaskStatus(TaskStatus status) => switch (status) {
  TaskStatus.completed => MascotMood.success,
  TaskStatus.failed => MascotMood.error,
  TaskStatus.cancelled => MascotMood.resting,
  TaskStatus.waitingApproval => MascotMood.curious,
  _ => MascotMood.thinking,
};

/// An original robin mascot for Phodex — hand-drawn as vector shapes (no
/// image asset, no borrowed character design), so it scales perfectly,
/// recolors with the theme, and animates its expression to match what the
/// agent is actually doing.
class PhodexMascot extends StatefulWidget {
  const PhodexMascot({super.key, this.mood = MascotMood.idle, this.size = 64});

  final MascotMood mood;
  final double size;

  @override
  State<PhodexMascot> createState() => _PhodexMascotState();
}

class _PhodexMascotState extends State<PhodexMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respects the OS "Reduce Motion" setting (and lets widget tests settle
    // without waiting out an intentionally-infinite decorative loop) instead
    // of always animating regardless of context.
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _RobinPainter(
          mood: widget.mood,
          t: _controller.value,
          colors: colors,
        ),
      ),
    );
  }
}

/// A single-color silhouette of the robin, for contexts that need one flat
/// tint instead of the full-color hero character — the tab bar's active/
/// inactive swap, small inline badges, anywhere an `Icon`-shaped glyph is
/// expected rather than a character illustration.
class PhodexMascotGlyph extends StatelessWidget {
  const PhodexMascotGlyph({super.key, this.size = 24, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size(size, size),
    painter: _RobinGlyphPainter(color: color),
  );
}

class _RobinGlyphPainter extends CustomPainter {
  _RobinGlyphPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Simplified deliberately for small, single-color contexts (tab bar):
    // a bold rounded body + one clear crest point. Fine detail (beak, eyes)
    // disappears at 24px, so it's dropped rather than left to smear into
    // visual noise — legibility at-size beats matching the hero illustration
    // stroke-for-stroke.
    final s = size.shortestSide;
    final o = Offset(size.width / 2, size.height / 2 + s * 0.02);
    final paint = Paint()..color = color;

    final body = Rect.fromCenter(center: o, width: s * 0.68, height: s * 0.62);
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, Radius.circular(s * 0.3)),
      paint,
    );

    final crest = Path()
      ..moveTo(o.dx - s * 0.12, o.dy - s * 0.28)
      ..lineTo(o.dx, o.dy - s * 0.48)
      ..lineTo(o.dx + s * 0.12, o.dy - s * 0.28)
      ..close();
    canvas.drawPath(crest, paint);
  }

  @override
  bool shouldRepaint(covariant _RobinGlyphPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _RobinPainter extends CustomPainter {
  _RobinPainter({required this.mood, required this.t, required this.colors});
  final MascotMood mood;
  final double t;
  final AppColors colors;

  double get _wave => math.sin(t * 2 * math.pi);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final center = Offset(size.width / 2, size.height / 2 + s * 0.04);

    final bob = mood == MascotMood.thinking ? _wave * s * 0.02 : 0.0;
    final tilt = mood == MascotMood.curious ? -0.14 : 0.0;
    final origin = center.translate(0, bob);

    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    if (tilt != 0) canvas.rotate(tilt);
    canvas.translate(-origin.dx, -origin.dy);

    _drawCrest(canvas, origin, s);
    _drawWings(canvas, origin, s);
    _drawBody(canvas, origin, s);
    _drawBreast(canvas, origin, s);
    _drawBeak(canvas, origin, s);
    _drawEyes(canvas, origin, s);

    canvas.restore();
  }

  void _drawCrest(Canvas canvas, Offset o, double s) {
    final lift = mood == MascotMood.thinking ? _wave.abs() * s * 0.015 : 0.0;
    final tipY = o.dy - s * 0.42 - lift;
    final path = Path()
      ..moveTo(o.dx - s * 0.06, o.dy - s * 0.34)
      ..quadraticBezierTo(o.dx - s * 0.03, tipY, o.dx, o.dy - s * 0.32)
      ..quadraticBezierTo(
        o.dx + s * 0.03,
        tipY,
        o.dx + s * 0.06,
        o.dy - s * 0.34,
      )
      ..close();
    canvas.drawPath(path, Paint()..color = colors.mascotBodyDark);

    final accentPulse = mood == MascotMood.thinking
        ? 0.6 + 0.4 * (0.5 + 0.5 * _wave)
        : 1.0;
    canvas.drawCircle(
      Offset(o.dx, tipY),
      s * 0.028,
      Paint()..color = colors.mascotAccent.withValues(alpha: accentPulse),
    );
  }

  void _drawWings(Canvas canvas, Offset o, double s) {
    final flutter = mood == MascotMood.thinking ? _wave * 0.12 : 0.0;
    final raised = mood == MascotMood.success ? -0.35 : 0.0;
    final drooped = mood == MascotMood.error ? 0.3 : 0.0;
    final rotation = flutter + raised + drooped;

    for (final side in [-1, 1]) {
      final anchor = Offset(o.dx + s * 0.32 * side, o.dy + s * 0.02);
      canvas.save();
      canvas.translate(anchor.dx, anchor.dy);
      canvas.rotate(rotation * side);
      final wing = Path()
        ..moveTo(0, -s * 0.06)
        ..quadraticBezierTo(s * 0.16 * side, s * 0.02, s * 0.1 * side, s * 0.22)
        ..quadraticBezierTo(s * 0.02 * side, s * 0.14, 0, s * 0.18)
        ..close();
      canvas.drawPath(wing, Paint()..color = colors.mascotBodyDark);
      canvas.restore();
    }
  }

  void _drawBody(Canvas canvas, Offset o, double s) {
    final rect = Rect.fromCenter(
      center: o.translate(0, s * 0.04),
      width: s * 0.76,
      height: s * 0.72,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(s * 0.34)),
      Paint()..color = colors.mascotBody,
    );
  }

  void _drawBreast(Canvas canvas, Offset o, double s) {
    final rect = Rect.fromCenter(
      center: o.translate(0, s * 0.14),
      width: s * 0.46,
      height: s * 0.4,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(s * 0.22)),
      Paint()..color = colors.mascotBreast,
    );
  }

  void _drawBeak(Canvas canvas, Offset o, double s) {
    final beakY = o.dy - s * 0.03;
    final open = mood == MascotMood.success || mood == MascotMood.error;
    final path = Path();
    if (open) {
      final gap = mood == MascotMood.success ? s * 0.05 : s * 0.03;
      path
        ..moveTo(o.dx - s * 0.07, beakY)
        ..lineTo(o.dx, beakY + gap)
        ..lineTo(o.dx + s * 0.07, beakY)
        ..lineTo(o.dx, beakY + s * 0.02)
        ..close();
    } else {
      path
        ..moveTo(o.dx - s * 0.07, beakY)
        ..lineTo(o.dx + s * 0.07, beakY)
        ..lineTo(o.dx, beakY + s * 0.045)
        ..close();
    }
    canvas.drawPath(path, Paint()..color = colors.mascotBeak);
  }

  void _drawEyes(Canvas canvas, Offset o, double s) {
    final eyeY = o.dy - s * 0.13;
    final eyeDx = s * 0.13;
    final white = Paint()..color = colors.mascotFace;
    final pupil = Paint()..color = colors.mascotEye;
    final stroke = Paint()
      ..color = colors.mascotEye
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.028
      ..strokeCap = StrokeCap.round;

    switch (mood) {
      case MascotMood.idle:
        for (final dx in [-eyeDx, eyeDx]) {
          canvas.drawCircle(Offset(o.dx + dx, eyeY), s * 0.06, white);
          canvas.drawCircle(Offset(o.dx + dx, eyeY), s * 0.032, pupil);
        }
      case MascotMood.thinking:
        final shift = _wave * s * 0.012;
        for (final dx in [-eyeDx, eyeDx]) {
          canvas.drawCircle(Offset(o.dx + dx, eyeY), s * 0.06, white);
          canvas.drawCircle(Offset(o.dx + dx + shift, eyeY), s * 0.032, pupil);
        }
      case MascotMood.curious:
        for (final dx in [-eyeDx, eyeDx]) {
          canvas.drawCircle(Offset(o.dx + dx, eyeY), s * 0.065, white);
          canvas.drawCircle(
            Offset(o.dx + dx + s * 0.018, eyeY + s * 0.01),
            s * 0.03,
            pupil,
          );
        }
        // One raised brow — the "?" read.
        canvas.drawLine(
          Offset(o.dx + eyeDx - s * 0.05, eyeY - s * 0.09),
          Offset(o.dx + eyeDx + s * 0.05, eyeY - s * 0.12),
          stroke,
        );
      case MascotMood.success:
        for (final dx in [-eyeDx, eyeDx]) {
          final r = Rect.fromCenter(
            center: Offset(o.dx + dx, eyeY + s * 0.02),
            width: s * 0.1,
            height: s * 0.1,
          );
          canvas.drawArc(r, math.pi, math.pi, false, stroke);
        }
      case MascotMood.error:
        for (final side in [-1, 1]) {
          final dx = eyeDx * side;
          canvas.drawCircle(Offset(o.dx + dx, eyeY), s * 0.05, white);
          canvas.drawCircle(
            Offset(o.dx + dx, eyeY + s * 0.012),
            s * 0.026,
            pupil,
          );
        }
        canvas.drawLine(
          Offset(o.dx - eyeDx - s * 0.045, eyeY - s * 0.075),
          Offset(o.dx - eyeDx + s * 0.045, eyeY - s * 0.045),
          stroke,
        );
        canvas.drawLine(
          Offset(o.dx + eyeDx + s * 0.045, eyeY - s * 0.075),
          Offset(o.dx + eyeDx - s * 0.045, eyeY - s * 0.045),
          stroke,
        );
      case MascotMood.resting:
        for (final dx in [-eyeDx, eyeDx]) {
          final path = Path()
            ..moveTo(o.dx + dx - s * 0.045, eyeY)
            ..quadraticBezierTo(
              o.dx + dx,
              eyeY + s * 0.025,
              o.dx + dx + s * 0.045,
              eyeY,
            );
          canvas.drawPath(path, stroke);
        }
    }
  }

  @override
  bool shouldRepaint(covariant _RobinPainter oldDelegate) =>
      oldDelegate.mood != mood ||
      oldDelegate.t != t ||
      oldDelegate.colors != colors;
}
