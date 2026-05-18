import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool highlight;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = AppRadii.card,
    this.highlight = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
        highlight ? const Color(0x527C3AED) : AppColors.border;

    Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            gradient:
                highlight ? AppGradients.glassHi : null,
            color: highlight ? null : AppColors.card,
            border: Border.all(color: borderColor, width: 1),
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Stack(
            children: [
              if (highlight)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppGradients.glassSheen,
                        borderRadius: BorderRadius.circular(radius),
                      ),
                    ),
                  ),
                ),
              Padding(padding: padding, child: child),
            ],
          ),
        ),
      ),
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: content,
        ),
      );
    }
    return content;
  }
}
