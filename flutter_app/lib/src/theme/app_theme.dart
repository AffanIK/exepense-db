import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Slip brand palette
  static const teal = Color(0xFF0F8F87);
  static const tealDeep = Color(0xFF0A6E68);
  static const butter = Color(0xFFFFE38A);
  static const pine = Color(0xFF0C2A28);
  static const cream = Color(0xFFF0EEE9);

  // Surfaces
  static const bg = cream;
  static const bg2 = Color(0xFFE8E5DC);
  static const bg3 = Color(0xFFFFFFFF);
  static const cardSolid = Color(0xFFFFFFFF);

  // Translucent surfaces over cream
  static const card = Color(0xE8FFFFFF);
  static const cardLow = Color(0xCCFFFFFF);
  static const border = Color(0x140C2A28);
  static const borderHi = Color(0x2A0C2A28);

  // Brand-mapped accents (legacy names retained so existing widgets compile)
  static const accent = teal;
  static const accent2 = butter;
  static const accent3 = tealDeep;
  static const glow = Color(0x4D0F8F87);

  // Semantic
  static const income = teal;
  static const incomeBg = Color(0x1F0F8F87);
  static const expense = Color(0xFFC24B3F);
  static const expenseBg = Color(0x1FC24B3F);

  // Ink (text on cream)
  static const text = pine;
  static const text2 = Color(0xB30C2A28);
  static const text3 = Color(0x800C2A28);
  static const text4 = Color(0x4D0C2A28);
}

class AppGradients {
  static const accent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.teal, AppColors.tealDeep],
  );

  static const butterWash = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFEFB4), Color(0xFFFFE38A)],
  );

  // Used by GlassCard(highlight:true) — frosted white tinted with teal
  static const glassHi = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xF2FFFFFF), Color(0xE6F4FCFB)],
  );

  // Inner sheen on highlighted glass — bright top, faint pine at bottom
  static const glassSheen = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.35, 0.65, 1.0],
    colors: [
      Color(0x80FFFFFF),
      Color(0x00FFFFFF),
      Color(0x00FFFFFF),
      Color(0x0F0C2A28),
    ],
  );

  static LinearGradient catTile(Color c) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [c.withOpacity(0.22), c.withOpacity(0.10)],
      );
}

class AppRadii {
  static const card = 24.0;
  static const tile = 12.0;
  static const pill = 999.0;
  static const input = 14.0;
  static const sheet = 28.0;
}

class AppDurations {
  static const stagger = Duration(milliseconds: 560);
  static const tabIn = Duration(milliseconds: 460);
  static const tap = Duration(milliseconds: 140);
  static const countUp = Duration(milliseconds: 1000);
  static const drawOn = Duration(milliseconds: 900);
  static const slide = Duration(milliseconds: 420);
}

class AppCurves {
  static const stagger = Cubic(.34, 1.3, .64, 1);
  static const tab = Cubic(.34, 1.45, .64, 1);
  static const tap = Cubic(.34, 1.4, .64, 1);
  static const draw = Cubic(.34, 1.2, .64, 1);
  static const spring = Cubic(.34, 1.5, .64, 1);
  static const slide = Cubic(.34, 1.4, .64, 1);
}

const _tabular = <FontFeature>[FontFeature.tabularFigures()];

ThemeData buildAppTheme() {
  final base = GoogleFonts.bricolageGrotesque(color: AppColors.text);
  final mono = GoogleFonts.jetBrainsMono(color: AppColors.text);

  final textTheme = TextTheme(
    displayLarge: base.copyWith(
      fontSize: 44,
      fontWeight: FontWeight.w700,
      letterSpacing: -1.8,
      height: 1.05,
      fontFeatures: _tabular,
    ),
    displayMedium: base.copyWith(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.9,
      fontFeatures: _tabular,
    ),
    headlineSmall: base.copyWith(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.8,
    ),
    titleLarge: base.copyWith(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
    ),
    titleMedium: base.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.3,
    ),
    bodyLarge: base.copyWith(fontSize: 15, letterSpacing: -0.2),
    bodyMedium: base.copyWith(fontSize: 14, letterSpacing: -0.1),
    bodySmall: base.copyWith(fontSize: 12, color: AppColors.text3),
    labelLarge: base.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
    labelMedium: base.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
      color: AppColors.text3,
    ),
  );

  final scheme = const ColorScheme.light(
    primary: AppColors.teal,
    onPrimary: Colors.white,
    secondary: AppColors.butter,
    onSecondary: AppColors.pine,
    surface: AppColors.cream,
    onSurface: AppColors.pine,
    error: AppColors.expense,
    onError: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bg,
    canvasColor: AppColors.bg,
    textTheme: textTheme,
    splashFactory: InkSparkle.splashFactory,
    splashColor: AppColors.teal.withOpacity(0.08),
    highlightColor: AppColors.teal.withOpacity(0.06),
    dividerColor: AppColors.border,
  );
}

TextStyle tabularize(TextStyle s) => s.copyWith(fontFeatures: _tabular);

/// Tabular mono number style — for amounts, percentages, counts.
TextStyle slipMono({
  double fontSize = 16,
  FontWeight fontWeight = FontWeight.w700,
  Color color = AppColors.pine,
  double letterSpacing = -0.4,
}) =>
    GoogleFonts.jetBrainsMono(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      fontFeatures: _tabular,
    );

/// Display style — Bricolage Grotesque headings.
TextStyle slipDisplay({
  double fontSize = 32,
  FontWeight fontWeight = FontWeight.w700,
  Color color = AppColors.pine,
  double letterSpacing = -0.9,
  double height = 1.05,
}) =>
    GoogleFonts.bricolageGrotesque(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      height: height,
      fontFeatures: _tabular,
    );
