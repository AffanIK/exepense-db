import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/category_meta.dart';

class CatTile extends StatelessWidget {
  final String categoryId;
  final double size;
  final double radius;

  const CatTile({
    super.key,
    required this.categoryId,
    this.size = 40,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final meta = metaFor(categoryId);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppGradients.catTile(meta.color),
        border: Border.all(color: meta.color.withOpacity(0.20)),
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: Icon(meta.icon, size: size * 0.5, color: meta.color),
    );
  }
}
