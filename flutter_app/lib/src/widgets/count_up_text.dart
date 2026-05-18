import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Animates a numeric value from 0 to [value] over [duration] using
/// [Curves.easeOutCubic], then formats via [formatter].
class CountUpText extends StatelessWidget {
  final double value;
  final TextStyle? style;
  final String Function(double) formatter;
  final Duration duration;
  final Duration delay;

  const CountUpText({
    super.key,
    required this.value,
    required this.formatter,
    this.style,
    this.duration = AppDurations.countUp,
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration + delay,
      curve: Interval(
        delay.inMilliseconds == 0
            ? 0
            : delay.inMilliseconds /
                (duration + delay).inMilliseconds.toDouble(),
        1.0,
        curve: Curves.easeOutCubic,
      ),
      builder: (context, v, _) => Text(
        formatter(v),
        style: (style ?? const TextStyle()).copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
