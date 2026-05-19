import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/slip_logo.dart';

/// One-shot splash. Fires [onDone] at the end of the animation; the parent
/// (SplashGate in main.dart) swaps in RootShell after that.
class SplashScreen extends StatefulWidget {
  final VoidCallback onDone;
  final Duration hold;

  const SplashScreen({
    super.key,
    required this.onDone,
    this.hold = const Duration(milliseconds: 1800),
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    Future.delayed(widget.hold, () {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Soft butter glow behind the mark
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.15),
                    radius: 0.65,
                    colors: [
                      AppColors.butter.withOpacity(0.28),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: _intro,
              builder: (context, _) {
                final t = Curves.easeOutCubic.transform(_intro.value);
                return Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(0, (1 - t) * 14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SlipMark(size: 104),
                        const SizedBox(height: 22),
                        const SlipWordmark(fontSize: 56),
                        const SizedBox(height: 12),
                        Text(
                          'SAVE THE SLIP',
                          style: GoogleFonts.bricolageGrotesque(
                            color: AppColors.text3,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 3.2,
                          ),
                        ),
                        const SizedBox(height: 36),
                        const _LoadingDots(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
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
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = ((_c.value * 3) - i).clamp(0.0, 1.0);
            final eased = (1 - (phase - 0.5).abs() * 2).clamp(0.0, 1.0);
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: Color.lerp(
                    AppColors.teal.withOpacity(0.25),
                    AppColors.teal,
                    eased,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
