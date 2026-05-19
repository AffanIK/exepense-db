import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class IconButtonGlass extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool dot;
  final double size;

  const IconButtonGlass({
    super.key,
    required this.icon,
    this.onPressed,
    this.dot = false,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.pine.withOpacity(0.06),
                offset: const Offset(0, 4),
                blurRadius: 10,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, size: 18, color: AppColors.pine),
              if (dot)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: AppColors.glow, blurRadius: 8),
                      ],
                      border: Border.all(color: AppColors.bg, width: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
