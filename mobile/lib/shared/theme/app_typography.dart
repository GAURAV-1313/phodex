import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTypography {
  const AppTypography._();

  static TextTheme textTheme = const TextTheme(
    displaySmall: TextStyle(
      fontSize: 34,
      height: 40 / 34,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      height: 34 / 28,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
    headlineSmall: TextStyle(
      fontSize: 22,
      height: 28 / 22,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      height: 24 / 16,
      fontWeight: FontWeight.w400,
      color: AppColors.textPrimary,
    ),
    bodyMedium: TextStyle(
      fontSize: 15,
      height: 22 / 15,
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondary,
    ),
    labelMedium: TextStyle(
      fontSize: 13,
      height: 18 / 13,
      fontWeight: FontWeight.w500,
      color: AppColors.textMuted,
    ),
  );

  static const TextStyle code = TextStyle(
    fontSize: 13,
    height: 18 / 13,
    fontFamily: 'monospace',
    color: AppColors.textSecondary,
  );
}
