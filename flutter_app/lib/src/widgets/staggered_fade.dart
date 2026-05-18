import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Wraps [child] with a subtle stagger-in motion: opacity 0→1 and a small
/// translateY (6→0). Kept short so that combined with the tab-switch
/// crossfade it doesn't make headings appear to "jump".
class StaggeredFade extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  const StaggeredFade({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 380),
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
        final translate = (1 - t) * 6.0;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, translate),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
