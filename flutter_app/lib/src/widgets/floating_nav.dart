import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NavItem {
  final IconData icon;
  final String id;
  const NavItem({required this.id, required this.icon});
}

class FloatingNav extends StatelessWidget {
  final List<NavItem> items;
  final int index;
  final ValueChanged<int> onTap;

  static const _itemSize = 56.0;
  static const _gap = 4.0;
  static const _pad = 6.0;

  const FloatingNav({
    super.key,
    required this.items,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = items.length * _itemSize + (items.length - 1) * _gap + _pad * 2;
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            width: width,
            padding: const EdgeInsets.all(_pad),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.78),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.borderHi),
              boxShadow: [
                BoxShadow(
                    color: AppColors.pine.withOpacity(0.10),
                    offset: const Offset(0, 14),
                    blurRadius: 32),
              ],
            ),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 480),
                  curve: AppCurves.spring,
                  left: index * (_itemSize + _gap),
                  top: 0,
                  width: _itemSize,
                  height: _itemSize,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppGradients.accent,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.teal.withOpacity(0.40),
                          offset: const Offset(0, 6),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(items.length, (i) {
                    final active = index == i;
                    return Padding(
                      padding: EdgeInsets.only(left: i == 0 ? 0 : _gap),
                      child: SizedBox(
                        width: _itemSize,
                        height: _itemSize,
                        child: Material(
                          color: Colors.transparent,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => onTap(i),
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 280),
                              style: TextStyle(
                                color: active
                                    ? Colors.white
                                    : AppColors.text3,
                              ),
                              child: Center(
                                child: Icon(
                                  items[i].icon,
                                  size: 22,
                                  color: active
                                      ? Colors.white
                                      : AppColors.text3,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
