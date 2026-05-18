import 'dart:ui';
import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF0F0F1A);
  static const bg2 = Color(0xFF16172B);
  static const bg3 = Color(0xFF1C1D33);
  static const cardSolid = Color(0xFF1A1B2E);

  static const card = Color(0x09FFFFFF);
  static const border = Color(0x12FFFFFF);
  static const borderHi = Color(0x24FFFFFF);

  static const accent = Color(0xFF7C3AED);
  static const accent2 = Color(0xFFA78BFA);
  static const accent3 = Color(0xFF5B21B6);
  static const glow = Color(0x8C7C3AED);

  static const income = Color(0xFF10E0A0);
  static const incomeBg = Color(0x1F10E0A0);
  static const expense = Color(0xFFFF5570);
  static const expenseBg = Color(0x1FFF5570);

  static const text = Color(0xFFFFFFFF);
  static const text2 = Color(0x9EFFFFFF);
  static const text3 = Color(0x61FFFFFF);
  static const text4 = Color(0x38FFFFFF);
}

class AppGradients {
  static const accent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.accent, AppColors.accent3],
  );

  static const glassHi = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x2E7C3AED), Color(0x0A7C3AED)],
  );

  static const glassSheen = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.35, 0.65, 1.0],
    colors: [
      Color(0x1AFFFFFF),
      Color(0x00FFFFFF),
      Color(0x00FFFFFF),
      Color(0x0AFFFFFF),
    ],
  );

  static LinearGradient catTile(Color c) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [c.withOpacity(0.20), c.withOpacity(0.08)],
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

const _fontStack = <String>[
  '.SF Pro Display',
  '.SF Pro Text',
  'Segoe UI',
  'Roboto',
  'system-ui',
];

const _tabular = <FontFeature>[FontFeature.tabularFigures()];

ThemeData buildAppTheme() {
  const base = TextStyle(color: AppColors.text);
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
      fontWeight: FontWeight.w600,
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

  final scheme = const ColorScheme.dark(
    primary: AppColors.accent,
    onPrimary: Colors.white,
    secondary: AppColors.accent2,
    onSecondary: Colors.white,
    surface: AppColors.bg,
    onSurface: AppColors.text,
    error: AppColors.expense,
    onError: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bg,
    canvasColor: AppColors.bg,
    fontFamily: _fontStack.first,
    fontFamilyFallback: _fontStack.skip(1).toList(),
    textTheme: textTheme,
    splashFactory: InkSparkle.splashFactory,
    splashColor: AppColors.accent.withOpacity(0.08),
    highlightColor: AppColors.accent.withOpacity(0.06),
    dividerColor: AppColors.border,
  );
}

TextStyle tabularize(TextStyle s) => s.copyWith(fontFeatures: _tabular);
