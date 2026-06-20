import 'package:flutter/material.dart';

import 'tokens.dart';

const roostySerifFontFamily = 'SourceHanSerifSC';
const roostyLatinDisplayFontFamily = 'Lora';

TextTheme buildRoostyTextTheme(RoostyTokens tokens) {
  const bodyFamily = roostySerifFontFamily;
  const displayFamily = roostyLatinDisplayFontFamily;
  const fallback = <String>[roostySerifFontFamily];

  TextStyle style({
    required double size,
    required FontWeight weight,
    required Color color,
    double height = 1.35,
    bool display = false,
  }) {
    return TextStyle(
      fontFamily: display ? displayFamily : bodyFamily,
      fontFamilyFallback: display ? fallback : null,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: 0,
      color: color,
    );
  }

  return TextTheme(
    displayLarge: style(
      size: 34,
      weight: FontWeight.w500,
      color: tokens.textPrimary,
      display: true,
    ),
    displayMedium: style(
      size: 28,
      weight: FontWeight.w500,
      color: tokens.textPrimary,
      display: true,
    ),
    headlineSmall: style(
      size: 22,
      weight: FontWeight.w600,
      color: tokens.textPrimary,
    ),
    titleLarge: style(
      size: 20,
      weight: FontWeight.w600,
      color: tokens.textPrimary,
      display: true,
    ),
    titleMedium: style(
      size: 17,
      weight: FontWeight.w600,
      color: tokens.textPrimary,
    ),
    titleSmall: style(
      size: 15,
      weight: FontWeight.w600,
      color: tokens.textPrimary,
    ),
    bodyLarge: style(
      size: 15,
      weight: FontWeight.w400,
      color: tokens.textPrimary,
    ),
    bodyMedium: style(
      size: 14,
      weight: FontWeight.w400,
      color: tokens.textPrimary,
    ),
    bodySmall: style(
      size: 12,
      weight: FontWeight.w400,
      color: tokens.textSecondary,
    ),
    labelLarge: style(
      size: 14,
      weight: FontWeight.w600,
      color: tokens.textPrimary,
    ),
    labelMedium: style(
      size: 13,
      weight: FontWeight.w600,
      color: tokens.textPrimary,
    ),
    labelSmall: style(
      size: 12,
      weight: FontWeight.w600,
      color: tokens.textSecondary,
    ),
  );
}
