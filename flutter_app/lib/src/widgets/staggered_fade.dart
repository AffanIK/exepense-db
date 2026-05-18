import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Wraps [child] with the design's stagger-in motion: opacity 0→1,
/// translateY 14→0, blur 2→0, over [duration] starting after [delay].
class StaggeredFade extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  const StaggeredFade({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppDurations.stagger,
  });

  @override
  State<StaggeredFade> createState() => _StaggeredFadeState();
}

class _StaggeredFadeState extends State<StaggeredFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration);

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = AppCurves.stagger.transform(_c.value);
        final translate = (1 - t) * 14.0;
        final blur = (1 - t) * 2.0;
        Widget body = Opacity(opacity: t, child: child);
        if (blur > 0.05) {
          body = ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: body,
          );
        }
        return Transform.translate(offset: Offset(0, translate), child: body);
      },
      child: widget.child,
    );
  }
}
