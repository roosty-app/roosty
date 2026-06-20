import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

@immutable
class RoostyTokens extends ThemeExtension<RoostyTokens> {
  const RoostyTokens({
    required this.bgBase,
    required this.bgCard,
    required this.bgElevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.primary,
    required this.onPrimary,
    required this.primaryHover,
    required this.primarySubtle,
    required this.divider,
    required this.error,
    required this.success,
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusLg,
    required this.radiusXl,
    required this.space1,
    required this.space2,
    required this.space3,
    required this.space4,
    required this.space6,
    required this.space8,
    required this.contentMaxWidth,
    required this.shadowSm,
    required this.shadowMd,
    required this.shadowLg,
  });

  final Color bgBase;
  final Color bgCard;
  final Color bgElevated;
  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;
  final Color primary;
  final Color onPrimary;
  final Color primaryHover;
  final Color primarySubtle;
  final Color divider;
  final Color error;
  final Color success;
  final double radiusSm;
  final double radiusMd;
  final double radiusLg;
  final double radiusXl;
  final double space1;
  final double space2;
  final double space3;
  final double space4;
  final double space6;
  final double space8;
  final double contentMaxWidth;
  final List<BoxShadow> shadowSm;
  final List<BoxShadow> shadowMd;
  final List<BoxShadow> shadowLg;

  static const light = RoostyTokens(
    bgBase: Color(0xFFFAF7F2),
    bgCard: Color(0xFFFFFFFF),
    bgElevated: Color(0xFFF2EBDF),
    textPrimary: Color(0xFF3A2E22),
    textSecondary: Color(0xFF7A6B5C),
    textDisabled: Color(0xFFB5A99A),
    primary: Color(0xFFB07C4E),
    onPrimary: Color(0xFFFAF7F2),
    primaryHover: Color(0xFF9D6C42),
    primarySubtle: Color(0xFFF4E8D9),
    divider: Color(0xFFE8DECF),
    error: Color(0xFFB45848),
    success: Color(0xFF5B7A6A),
    radiusSm: 6,
    radiusMd: 12,
    radiusLg: 16,
    radiusXl: 24,
    space1: 4,
    space2: 8,
    space3: 12,
    space4: 16,
    space6: 24,
    space8: 32,
    contentMaxWidth: 720,
    shadowSm: [
      BoxShadow(color: Color(0x0F3A2E22), blurRadius: 2, offset: Offset(0, 1)),
    ],
    shadowMd: [
      BoxShadow(color: Color(0x143A2E22), blurRadius: 12, offset: Offset(0, 4)),
    ],
    shadowLg: [
      BoxShadow(
        color: Color(0x1A3A2E22),
        blurRadius: 32,
        offset: Offset(0, 12),
      ),
    ],
  );

  static const dark = RoostyTokens(
    bgBase: Color(0xFF1F1B17),
    bgCard: Color(0xFF2A2520),
    bgElevated: Color(0xFF332D27),
    textPrimary: Color(0xFFEDE5D8),
    textSecondary: Color(0xFF9C8E7E),
    textDisabled: Color(0xFF6B5F52),
    primary: Color(0xFFD89968),
    onPrimary: Color(0xFF1F1B17),
    primaryHover: Color(0xFFE5A878),
    primarySubtle: Color(0xFF3D2F22),
    divider: Color(0xFF3A332C),
    error: Color(0xFFD87A6A),
    success: Color(0xFF7A9483),
    radiusSm: 6,
    radiusMd: 12,
    radiusLg: 16,
    radiusXl: 24,
    space1: 4,
    space2: 8,
    space3: 12,
    space4: 16,
    space6: 24,
    space8: 32,
    contentMaxWidth: 720,
    shadowSm: [
      BoxShadow(color: Color(0x66000000), blurRadius: 2, offset: Offset(0, 1)),
    ],
    shadowMd: [
      BoxShadow(color: Color(0x66000000), blurRadius: 12, offset: Offset(0, 4)),
    ],
    shadowLg: [
      BoxShadow(
        color: Color(0x66000000),
        blurRadius: 32,
        offset: Offset(0, 12),
      ),
    ],
  );

  @override
  RoostyTokens copyWith({
    Color? bgBase,
    Color? bgCard,
    Color? bgElevated,
    Color? textPrimary,
    Color? textSecondary,
    Color? textDisabled,
    Color? primary,
    Color? onPrimary,
    Color? primaryHover,
    Color? primarySubtle,
    Color? divider,
    Color? error,
    Color? success,
    double? radiusSm,
    double? radiusMd,
    double? radiusLg,
    double? radiusXl,
    double? space1,
    double? space2,
    double? space3,
    double? space4,
    double? space6,
    double? space8,
    double? contentMaxWidth,
    List<BoxShadow>? shadowSm,
    List<BoxShadow>? shadowMd,
    List<BoxShadow>? shadowLg,
  }) {
    return RoostyTokens(
      bgBase: bgBase ?? this.bgBase,
      bgCard: bgCard ?? this.bgCard,
      bgElevated: bgElevated ?? this.bgElevated,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textDisabled: textDisabled ?? this.textDisabled,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      primaryHover: primaryHover ?? this.primaryHover,
      primarySubtle: primarySubtle ?? this.primarySubtle,
      divider: divider ?? this.divider,
      error: error ?? this.error,
      success: success ?? this.success,
      radiusSm: radiusSm ?? this.radiusSm,
      radiusMd: radiusMd ?? this.radiusMd,
      radiusLg: radiusLg ?? this.radiusLg,
      radiusXl: radiusXl ?? this.radiusXl,
      space1: space1 ?? this.space1,
      space2: space2 ?? this.space2,
      space3: space3 ?? this.space3,
      space4: space4 ?? this.space4,
      space6: space6 ?? this.space6,
      space8: space8 ?? this.space8,
      contentMaxWidth: contentMaxWidth ?? this.contentMaxWidth,
      shadowSm: shadowSm ?? this.shadowSm,
      shadowMd: shadowMd ?? this.shadowMd,
      shadowLg: shadowLg ?? this.shadowLg,
    );
  }

  @override
  RoostyTokens lerp(ThemeExtension<RoostyTokens>? other, double t) {
    if (other is! RoostyTokens) {
      return this;
    }
    return RoostyTokens(
      bgBase: Color.lerp(bgBase, other.bgBase, t)!,
      bgCard: Color.lerp(bgCard, other.bgCard, t)!,
      bgElevated: Color.lerp(bgElevated, other.bgElevated, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      primaryHover: Color.lerp(primaryHover, other.primaryHover, t)!,
      primarySubtle: Color.lerp(primarySubtle, other.primarySubtle, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      error: Color.lerp(error, other.error, t)!,
      success: Color.lerp(success, other.success, t)!,
      radiusSm: lerpDouble(radiusSm, other.radiusSm, t)!,
      radiusMd: lerpDouble(radiusMd, other.radiusMd, t)!,
      radiusLg: lerpDouble(radiusLg, other.radiusLg, t)!,
      radiusXl: lerpDouble(radiusXl, other.radiusXl, t)!,
      space1: lerpDouble(space1, other.space1, t)!,
      space2: lerpDouble(space2, other.space2, t)!,
      space3: lerpDouble(space3, other.space3, t)!,
      space4: lerpDouble(space4, other.space4, t)!,
      space6: lerpDouble(space6, other.space6, t)!,
      space8: lerpDouble(space8, other.space8, t)!,
      contentMaxWidth: lerpDouble(contentMaxWidth, other.contentMaxWidth, t)!,
      shadowSm: BoxShadow.lerpList(shadowSm, other.shadowSm, t)!,
      shadowMd: BoxShadow.lerpList(shadowMd, other.shadowMd, t)!,
      shadowLg: BoxShadow.lerpList(shadowLg, other.shadowLg, t)!,
    );
  }
}

extension RoostyThemeTokens on BuildContext {
  RoostyTokens get roostyTokens {
    return Theme.of(this).extension<RoostyTokens>() ?? RoostyTokens.light;
  }
}
