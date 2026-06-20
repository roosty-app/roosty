import 'package:flutter/material.dart';

import 'text_theme.dart';
import 'tokens.dart';

ThemeData buildRoostyTheme({
  required RoostyTokens tokens,
  required Brightness brightness,
}) {
  final textTheme = buildRoostyTextTheme(tokens);
  final isDark = brightness == Brightness.dark;
  final colorScheme = isDark
      ? ColorScheme.dark(
          primary: tokens.primary,
          onPrimary: tokens.onPrimary,
          primaryContainer: tokens.primarySubtle,
          onPrimaryContainer: tokens.textPrimary,
          secondary: tokens.success,
          onSecondary: tokens.bgBase,
          surface: tokens.bgBase,
          onSurface: tokens.textPrimary,
          error: tokens.error,
          onError: tokens.bgBase,
          outline: tokens.divider,
          surfaceContainerHighest: tokens.bgElevated,
          onSurfaceVariant: tokens.textSecondary,
        )
      : ColorScheme.light(
          primary: tokens.primary,
          onPrimary: tokens.onPrimary,
          primaryContainer: tokens.primarySubtle,
          onPrimaryContainer: tokens.textPrimary,
          secondary: tokens.success,
          onSecondary: tokens.bgCard,
          surface: tokens.bgBase,
          onSurface: tokens.textPrimary,
          error: tokens.error,
          onError: tokens.bgCard,
          outline: tokens.divider,
          surfaceContainerHighest: tokens.bgElevated,
          onSurfaceVariant: tokens.textSecondary,
        );

  final roundedMd = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(tokens.radiusMd),
  );
  final roundedLg = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(tokens.radiusLg),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: tokens.bgBase,
    textTheme: textTheme,
    fontFamily: roostySerifFontFamily,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    hoverColor: tokens.primarySubtle,
    focusColor: tokens.primarySubtle,
    appBarTheme: AppBarTheme(
      backgroundColor: tokens.bgBase,
      foregroundColor: tokens.textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge,
      surfaceTintColor: Colors.transparent,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: tokens.bgCard,
      surfaceTintColor: Colors.transparent,
      shape: roundedLg,
      titleTextStyle: textTheme.titleMedium,
      contentTextStyle: textTheme.bodyMedium,
    ),
    dividerTheme: DividerThemeData(
      color: tokens.divider,
      thickness: 1,
      space: tokens.space4,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: tokens.textSecondary,
      textColor: tokens.textPrimary,
      titleTextStyle: textTheme.bodyMedium,
      subtitleTextStyle: textTheme.bodySmall,
      shape: roundedMd,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: tokens.bgCard,
      labelStyle: textTheme.bodySmall,
      hintStyle: textTheme.bodySmall?.copyWith(color: tokens.textDisabled),
      contentPadding: EdgeInsets.symmetric(
        horizontal: tokens.space4,
        vertical: tokens.space3,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        borderSide: BorderSide(color: tokens.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        borderSide: BorderSide(color: tokens.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        borderSide: BorderSide(color: tokens.primary, width: 1.4),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        borderSide: BorderSide(color: tokens.divider),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        minimumSize: WidgetStatePropertyAll(Size(44, 40)),
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(
            horizontal: tokens.space4,
            vertical: tokens.space2,
          ),
        ),
        shape: WidgetStatePropertyAll(roundedMd),
        textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return tokens.bgElevated;
          }
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.pressed)) {
            return tokens.primaryHover;
          }
          return tokens.primary;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return tokens.textDisabled;
          }
          return tokens.onPrimary;
        }),
        overlayColor: WidgetStatePropertyAll(tokens.primarySubtle),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(
            horizontal: tokens.space3,
            vertical: tokens.space2,
          ),
        ),
        shape: WidgetStatePropertyAll(roundedMd),
        textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return tokens.textDisabled;
          }
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.pressed)) {
            return tokens.primaryHover;
          }
          return tokens.primary;
        }),
        overlayColor: WidgetStatePropertyAll(tokens.primarySubtle),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        iconColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return tokens.textDisabled;
          }
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.pressed)) {
            return tokens.primary;
          }
          return tokens.textPrimary;
        }),
        overlayColor: WidgetStatePropertyAll(tokens.primarySubtle),
        shape: WidgetStatePropertyAll(roundedMd),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return tokens.textDisabled;
        }
        if (states.contains(WidgetState.selected)) {
          return tokens.primary;
        }
        return tokens.textSecondary;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return tokens.bgElevated;
        }
        if (states.contains(WidgetState.selected)) {
          return tokens.primarySubtle;
        }
        return tokens.bgElevated;
      }),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: tokens.primary,
      linearTrackColor: tokens.bgElevated,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: tokens.primary,
      selectionColor: tokens.primarySubtle,
      selectionHandleColor: tokens.primary,
    ),
    disabledColor: tokens.textDisabled,
    extensions: [tokens],
  );
}
