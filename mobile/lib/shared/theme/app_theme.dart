import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radii.dart';
import 'app_typography.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(Brightness.light, AppColors.light);

  static ThemeData dark() => _build(Brightness.dark, AppColors.dark);

  static ThemeData _build(Brightness brightness, AppColors palette) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: palette.bgPrimary,
      colorScheme: brightness == Brightness.light
          ? ColorScheme.light(
              surface: palette.bgSurface,
              primary: palette.accentPrimary,
              error: palette.accentError,
            )
          : ColorScheme.dark(
              surface: palette.bgSurface,
              primary: palette.accentPrimary,
              error: palette.accentError,
            ),
      textTheme: AppTypography.textTheme(palette),
      extensions: [palette],
    );

    return base.copyWith(
      cardTheme: CardThemeData(
        color: palette.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.bgInput,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.input),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.input),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.input),
          borderSide: BorderSide(color: palette.accentPrimary),
        ),
      ),
    );
  }
}
