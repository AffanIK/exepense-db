import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CircularProgressRing extends StatelessWidget {
  final double pct;
  final double size;
  final double stroke;
  final Color color;
  final Duration delay;
  final Widget? center;

  const CircularProgressRing({
    super.key,
    required this.pct,
    this.size = 88,
    this.stroke = 8,
    this.color = AppColors.accent,
    this.delay = Duration.zero,
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = pct.clamp(0, 100).toDouble() / 100.0;
    final over = pct > 100;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: clamped),
            duration: const Duration(milliseconds: 1000) + delay,
            curve: Interval(
              delay.inMilliseconds == 0
                  ? 0
                  : delay.inMilliseconds /
                      (const Duration(milliseconds: 1000) + delay)
                          .inMilliseconds
                          .toDouble(),
              1.0,
              curve: AppCurves.draw,
            ),
            builder: (context, v, _) => CustomPaint(
              size: Size.square(size),
              painter: _RingPainter(
                progress: v,
                stroke: stroke,
                color: over ? AppColors.expense : color,
              ),
            ),
          ),
          if (center != null) center!,
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final double stroke;
  final Color color;

  _RingPainter({
    required this.progress,
    required this.stroke,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final r = (size.width - stroke) / 2;
    final center = size.center(Offset.zero);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = const Color(0x0FFFFFFF);
    canvas.drawCircle(center, r, track);

    if (progress <= 0) return;

    final rect = Rect.fromCircle(center: center, radius: r);
    final sweep = 2 * math.pi * progress;

    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color.withOpacity(0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawArc(rect, -math.pi / 2, sweep, false, glow);

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi * 2 - math.pi / 2,
        colors: [color, color.withOpacity(0.55)],
      ).createShader(rect);
    canvas.drawArc(rect, -math.pi / 2, sweep, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter o) =>
      o.progress != progress || o.color != color || o.stroke != stroke;
}
