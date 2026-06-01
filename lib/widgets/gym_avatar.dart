import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:aura_fit/blocs/workout/workout_bloc.dart';
import 'package:aura_fit/theme/app_theme.dart';

// ─── Public Widget ────────────────────────────────────────────────────────────

class GymAvatar extends StatefulWidget {
  const GymAvatar({
    super.key,
    required this.avatarState,
    this.size = 180,
  });

  final AvatarState avatarState;
  final double      size;

  @override
  State<GymAvatar> createState() => _GymAvatarState();
}

class _GymAvatarState extends State<GymAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // Each AvatarState has its own animation curve / range.
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this);
    _applyState(widget.avatarState, initial: true);
  }

  @override
  void didUpdateWidget(GymAvatar old) {
    super.didUpdateWidget(old);
    if (old.avatarState != widget.avatarState) {
      _applyState(widget.avatarState);
    }
  }

  void _applyState(AvatarState s, {bool initial = false}) {
    _ctrl.stop();
    switch (s) {
      case AvatarState.idle:
        _ctrl.duration = const Duration(seconds: 3);
        _anim = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
        );
        _ctrl.repeat(reverse: true);
      case AvatarState.exercising:
        _ctrl.duration = const Duration(milliseconds: 600);
        _anim = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
        );
        _ctrl.repeat(reverse: true);
      case AvatarState.resting:
        _ctrl.duration = const Duration(seconds: 2);
        _anim = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
        );
        _ctrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _AvatarPainter(
          state:    widget.avatarState,
          progress: _anim.value,
        ),
      ),
    );
  }
}

// ─── Painter ──────────────────────────────────────────────────────────────────

class _AvatarPainter extends CustomPainter {
  _AvatarPainter({required this.state, required this.progress});

  final AvatarState state;
  final double      progress; // 0 → 1

  static const _primary   = kAccent;
  static const _secondary = kIndigo;
  static const _body      = Color(0xFF1E293B);

  @override
  void paint(Canvas canvas, Size size) {
    final cx   = size.width  / 2;
    final cy   = size.height / 2;
    final unit = size.width  / 12; // base unit

    // Glow backdrop
    final glowPaint = Paint()
      ..color = _primary.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
    canvas.drawCircle(Offset(cx, cy), size.width * 0.44, glowPaint);

    switch (state) {
      case AvatarState.idle:
        _drawIdle(canvas, cx, cy, unit, progress);
      case AvatarState.exercising:
        _drawExercising(canvas, cx, cy, unit, progress);
      case AvatarState.resting:
        _drawResting(canvas, cx, cy, unit, progress);
    }
  }

  // ── Idle — gentle floating bob ──────────────────────────────────────────────
  void _drawIdle(Canvas canvas, double cx, double cy, double u, double t) {
    final bob = math.sin(t * math.pi) * u * 0.3;

    _drawShadow(canvas, cx, cy + u * 4.5, u * 1.4, 1 - t * 0.2);

    // Body
    _drawBody(canvas, cx, cy + bob, u);

    // Subtle arm swing
    final armAngle = t * 0.15;
    _drawArm(canvas, cx, cy + bob, u, left: true,  angle: -armAngle);
    _drawArm(canvas, cx, cy + bob, u, left: false, angle:  armAngle);

    // Legs straight
    _drawLeg(canvas, cx, cy + bob, u, left: true,  angle: 0);
    _drawLeg(canvas, cx, cy + bob, u, left: false, angle: 0);

    // Head
    _drawHead(canvas, cx, cy + bob, u);

    // Energy dots
    _drawEnergyDots(canvas, cx, cy + bob, u, t, color: _primary);
  }

  // ── Exercising — push-up motion ─────────────────────────────────────────────
  void _drawExercising(Canvas canvas, double cx, double cy, double u, double t) {
    final squat = math.sin(t * math.pi) * u * 1.2;

    _drawShadow(canvas, cx, cy + u * 4.2, u * 1.6, 0.9 + t * 0.1);

    // Body lowers as squat deepens
    _drawBody(canvas, cx, cy + squat * 0.4, u, scale: 1 + t * 0.05);

    // Arms push outward during exercise
    final armOut = t * 0.6;
    _drawArm(canvas, cx, cy + squat * 0.4, u, left: true,  angle: -0.3 - armOut);
    _drawArm(canvas, cx, cy + squat * 0.4, u, left: false, angle:  0.3 + armOut);

    // Legs bend into squat
    _drawLeg(canvas, cx, cy + squat * 0.4, u, left: true,  angle: -(0.2 + t * 0.4));
    _drawLeg(canvas, cx, cy + squat * 0.4, u, left: false, angle:   0.2 + t * 0.4);

    _drawHead(canvas, cx, cy + squat * 0.4, u);

    // Faster energy dots in accent colour
    _drawEnergyDots(canvas, cx, cy + squat * 0.4, u, t, color: _secondary, count: 6);

    // Effort lines
    _drawEffortLines(canvas, cx, cy + squat * 0.4, u, t);
  }

  // ── Resting — seated lean ────────────────────────────────────────────────────
  void _drawResting(Canvas canvas, double cx, double cy, double u, double t) {
    final breathe = math.sin(t * math.pi) * u * 0.12;

    _drawShadow(canvas, cx, cy + u * 3.8, u * 1.8, 0.8);

    // Seated body shifted down/right
    final bx = cx + u * 0.3;
    final by = cy + u * 1.2 + breathe;

    _drawBody(canvas, bx, by, u, scale: 0.95);

    // Arms resting down
    _drawArm(canvas, bx, by, u, left: true,  angle:  0.4);
    _drawArm(canvas, bx, by, u, left: false, angle: -0.4);

    // Legs extended / bent at rest
    _drawLeg(canvas, bx, by, u, left: true,  angle: -0.5);
    _drawLeg(canvas, bx, by, u, left: false, angle:  0.5);

    _drawHead(canvas, bx, by, u);

    // Slow rising breath dots
    _drawBreathDots(canvas, bx, by, u, t);
  }

  // ── Shared Body Parts ────────────────────────────────────────────────────────

  void _drawShadow(Canvas canvas, double cx, double cy, double rx, double alpha) {
    final p = Paint()
      ..color = Colors.black.withValues(alpha: 0.35 * alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: rx * 0.6),
      p,
    );
  }

  void _drawBody(Canvas canvas, double cx, double cy, double u,
      {double scale = 1}) {
    final fill = Paint()..color = _body;
    final border = Paint()
      ..color = _primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = u * 0.18;

    // Torso
    final torso = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width:  u * 2.0 * scale,
        height: u * 2.6 * scale,
      ),
      Radius.circular(u * 0.6),
    );
    canvas.drawRRect(torso, fill);
    canvas.drawRRect(torso, border);

    // Chest line detail
    final detailP = Paint()
      ..color = _primary.withValues(alpha: 0.4)
      ..strokeWidth = u * 0.1;
    canvas.drawLine(
      Offset(cx, cy - u * 0.8),
      Offset(cx, cy + u * 0.5),
      detailP,
    );
  }

  void _drawArm(Canvas canvas, double cx, double cy, double u,
      {required bool left, required double angle}) {
    final side   = left ? -1.0 : 1.0;
    final startX = cx + side * u * 1.1;
    final startY = cy - u * 0.6;
    final endX   = startX + side * math.cos(angle + math.pi / 2) * u * 1.6;
    final endY   = startY + math.sin(angle + math.pi / 2) * u * 1.6;

    final p = Paint()
      ..color       = _primary
      ..strokeWidth = u * 0.5
      ..strokeCap   = StrokeCap.round;
    canvas.drawLine(Offset(startX, startY), Offset(endX, endY), p);

    // Fist
    canvas.drawCircle(Offset(endX, endY), u * 0.3, Paint()..color = _primary);
  }

  void _drawLeg(Canvas canvas, double cx, double cy, double u,
      {required bool left, required double angle}) {
    final side   = left ? -1.0 : 1.0;
    final startX = cx + side * u * 0.55;
    final startY = cy + u * 1.3;
    final endX   = startX + side * math.sin(angle) * u * 1.5;
    final endY   = startY + math.cos(angle)        * u * 1.8;

    final p = Paint()
      ..color       = _secondary
      ..strokeWidth = u * 0.55
      ..strokeCap   = StrokeCap.round;
    canvas.drawLine(Offset(startX, startY), Offset(endX, endY), p);

    // Foot
    canvas.drawCircle(
      Offset(endX, endY),
      u * 0.28,
      Paint()..color = _secondary,
    );
  }

  void _drawHead(Canvas canvas, double cx, double cy, double u) {
    final headY = cy - u * 1.8;

    // Glow ring
    canvas.drawCircle(
      Offset(cx, headY),
      u * 0.75,
      Paint()
        ..color      = _primary.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Head
    canvas.drawCircle(
      Offset(cx, headY),
      u * 0.65,
      Paint()..color = _body,
    );
    canvas.drawCircle(
      Offset(cx, headY),
      u * 0.65,
      Paint()
        ..color      = _primary
        ..style      = PaintingStyle.stroke
        ..strokeWidth = u * 0.15,
    );

    // Eyes
    final eyeY = headY - u * 0.1;
    for (final ex in [cx - u * 0.22, cx + u * 0.22]) {
      canvas.drawCircle(Offset(ex, eyeY), u * 0.12, Paint()..color = _primary);
    }
  }

  void _drawEnergyDots(
    Canvas canvas,
    double cx,
    double cy,
    double u,
    double t, {
    Color color    = _primary,
    int   count    = 4,
  }) {
    final p = Paint()..color = color.withValues(alpha: 0.7);
    for (int i = 0; i < count; i++) {
      final angle  = (i / count) * math.pi * 2 + t * math.pi * 2;
      final radius = u * (2.2 + math.sin(t * math.pi + i) * 0.4);
      final dx     = cx + math.cos(angle) * radius;
      final dy     = cy + math.sin(angle) * radius * 0.6;
      canvas.drawCircle(Offset(dx, dy), u * 0.14, p);
    }
  }

  void _drawEffortLines(
      Canvas canvas, double cx, double cy, double u, double t) {
    final p = Paint()
      ..color      = kWarning.withValues(alpha: 0.6 * t)
      ..strokeWidth = u * 0.1
      ..strokeCap   = StrokeCap.round;
    for (int i = 0; i < 3; i++) {
      final y = cy - u * (0.8 + i * 0.5);
      canvas.drawLine(
        Offset(cx + u * 1.6, y),
        Offset(cx + u * 2.2 + t * u * 0.4, y),
        p,
      );
    }
  }

  void _drawBreathDots(
      Canvas canvas, double cx, double cy, double u, double t) {
    final p = Paint()..color = kIndigo.withValues(alpha: 0.5);
    for (int i = 0; i < 3; i++) {
      final rise = (t + i * 0.33) % 1.0;
      canvas.drawCircle(
        Offset(cx + u * (1.2 + i * 0.3), cy - u * (0.5 + rise * 2.5)),
        u * (0.1 + rise * 0.08),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_AvatarPainter old) =>
      old.progress != progress || old.state != state;
}