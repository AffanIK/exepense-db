import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

const _slipIconAsset = 'assets/branding/slip_icon.png';

/// The Slip mark — teal rounded square with the butter S-receipt glyph.
/// Rendered from the cropped brand-sheet asset.
class SlipMark extends StatelessWidget {
  final double size;
  final double? radius;

  const SlipMark({super.key, this.size = 56, this.radius});

  @override
  Widget build(BuildContext context) {
    final r = radius ?? size * 0.225;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        boxShadow: [
          BoxShadow(
            color: AppColors.tealDeep.withOpacity(0.18),
            offset: const Offset(0, 8),
            blurRadius: 22,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r),
        child: Image.asset(
          _slipIconAsset,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

/// "slip" lowercase wordmark in Bricolage Grotesque 700, -3% tracking.
class SlipWordmark extends StatelessWidget {
  final double fontSize;
  final Color? color;

  const SlipWordmark({super.key, this.fontSize = 40, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      'slip',
      style: GoogleFonts.bricolageGrotesque(
        color: color ?? AppColors.pine,
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        letterSpacing: fontSize * -0.03,
        height: 1.0,
      ),
    );
  }
}

/// Mark + wordmark together. Used on splash and (smaller) in headers.
class SlipLockup extends StatelessWidget {
  final Axis axis;
  final double markSize;
  final double wordSize;
  final Color? inkColor;
  final double gap;

  const SlipLockup({
    super.key,
    this.axis = Axis.horizontal,
    this.markSize = 56,
    this.wordSize = 44,
    this.inkColor,
    this.gap = 12,
  });

  @override
  Widget build(BuildContext context) {
    final children = [
      SlipMark(size: markSize),
      SizedBox(width: axis == Axis.horizontal ? gap : 0, height: axis == Axis.vertical ? gap : 0),
      SlipWordmark(fontSize: wordSize, color: inkColor),
    ];
    return axis == Axis.horizontal
        ? Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: children)
        : Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: children);
  }
}
