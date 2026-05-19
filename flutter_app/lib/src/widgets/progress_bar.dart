import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AnimatedProgressBar extends StatelessWidget {
  final double pct;
  final Color color;
  final Duration delay;
  final double height;

  const AnimatedProgressBar({
    super.key,
    required this.pct,
    this.color = AppColors.accent,
    this.delay = Duration.zero,
    this.height = 6,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final fraction = (pct.clamp(0, 100)) / 100.0;
        return ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: height,
            color: AppColors.pine.withOpacity(0.06),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: fraction),
                duration: AppDurations.drawOn + delay,
                curve: Interval(
                  delay.inMilliseconds == 0
                      ? 0
                      : delay.inMilliseconds /
                          (AppDurations.drawOn + delay)
                              .inMilliseconds
                              .toDouble(),
                  1.0,
                  curve: AppCurves.draw,
                ),
                builder: (context, v, _) => Container(
                  width: c.maxWidth * v,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.85), color],
                    ),
                    boxShadow: [
                      BoxShadow(color: color.withOpacity(0.28), blurRadius: 8),
                    ],
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
