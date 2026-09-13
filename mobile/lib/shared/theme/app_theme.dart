import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radii.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Builds the two app themes from the token files. Every Material component
/// the app uses is themed here, so screens never need `styleFrom` overrides
/// and a `Chip`, `Divider`, or `OutlinedButton` dropped into any screen
/// automatically looks like it belongs.
class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(Brightness.light, AppColors.light);

  static ThemeData dark() => _build(Brightness.dark, AppColors.dark);

  static ThemeData _build(Brightness brightness, AppColors palette) {
    final textTheme = AppTypography.textTheme(palette);
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: palette.accentPrimary,
      onPrimary: palette.onAccent,
      primaryContainer: palette.accentPrimarySoft,
      onPrimaryContainer: palette.accentPrimaryDeep,
      secondary: palette.accentPrimaryDeep,
      onSecondary: palette.onAccent,
      secondaryContainer: palette.accentPrimarySoft,
      onSecondaryContainer: palette.textPrimary,
      tertiary: palette.accentWarning,
      onTertiary: palette.onAccent,
      tertiaryContainer: palette.bgInput,
      onTertiaryContainer: palette.textPrimary,
      error: palette.accentError,
      onError: palette.onAccent,
      errorContainer: palette.accentError.withValues(alpha: .12),
      onErrorContainer: palette.accentError,
      surface: palette.bgSurface,
      onSurface: palette.textPrimary,
      surfaceContainerLowest: palette.bgPrimary,
      surfaceContainerLow: palette.bgSurface,
      surfaceContainer: palette.bgCard,
      surfaceContainerHigh: palette.bgInput,
      surfaceContainerHighest: palette.bgInput,
      onSurfaceVariant: palette.textSecondary,
      outline: palette.borderSubtle,
      outlineVariant: palette.borderSubtle,
      shadow: palette.shadow,
      scrim: palette.scrim,
      inverseSurface: palette.textPrimary,
      onInverseSurface: palette.bgPrimary,
      inversePrimary: palette.accentPrimarySoft,
      surfaceTint: Colors.transparent,
    );

    final roundedButton = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.button),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.bgPrimary,
      canvasColor: palette.bgPrimary,
      splashFactory: InkSparkle.splashFactory,
      textTheme: textTheme,
      iconTheme: IconThemeData(color: palette.textPrimary, size: 24),
      dividerTheme: DividerThemeData(
        color: palette.borderSubtle,
        thickness: 1,
        space: AppSpacing.s16,
      ),
      cardTheme: CardThemeData(
        color: palette.bgCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.bgInput,
        hintStyle: textTheme.bodyLarge?.copyWith(color: palette.textMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s20,
          vertical: AppSpacing.s16,
        ),
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
          borderSide: BorderSide(color: palette.accentPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.input),
          borderSide: BorderSide(color: palette.accentError),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.accentPrimary,
          foregroundColor: palette.onAccent,
          disabledBackgroundColor: palette.accentPrimary.withValues(alpha: .4),
          disabledForegroundColor: palette.onAccent.withValues(alpha: .8),
          minimumSize: const Size(AppSpacing.s48, AppSpacing.s48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
          shape: roundedButton,
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.textPrimary,
          side: BorderSide(color: palette.borderSubtle),
          minimumSize: const Size(AppSpacing.s48, AppSpacing.s48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
          shape: roundedButton,
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.accentPrimary,
          minimumSize: const Size(AppSpacing.s48, AppSpacing.s48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
          shape: roundedButton,
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: palette.textPrimary,
          minimumSize: const Size(AppSpacing.s48, AppSpacing.s48),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: palette.bgInput,
        selectedColor: palette.accentPrimarySoft,
        disabledColor: palette.bgInput.withValues(alpha: .5),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.chip),
        ),
        labelStyle: textTheme.labelLarge?.copyWith(color: palette.textPrimary),
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(
          color: palette.accentPrimaryDeep,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s12,
          vertical: AppSpacing.s8,
        ),
        iconTheme: IconThemeData(color: palette.textSecondary, size: 18),
        showCheckmark: false,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: palette.accentPrimary,
        linearTrackColor: palette.bgInput,
        circularTrackColor: palette.bgInput,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.onAccent
              : palette.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.accentPrimary
              : palette.bgInput,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.bgSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.bgSurface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: palette.bgSurface,
        showDragHandle: true,
        dragHandleColor: palette.borderSubtle,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.sheet),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.textPrimary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: palette.bgPrimary,
        ),
        actionTextColor: palette.accentPrimarySoft,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.button),
        ),
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: palette.accentError,
        textColor: palette.onAccent,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: palette.textSecondary,
        textColor: palette.textPrimary,
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle: textTheme.bodySmall,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.global),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStatePropertyAll(palette.accentPrimary),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.accentPrimary
              : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(palette.onAccent),
        side: BorderSide(color: palette.borderSubtle, width: 1.5),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: palette.textPrimary,
          borderRadius: BorderRadius.circular(AppRadii.chip),
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: palette.bgPrimary),
      ),
      extensions: [palette],
    );
  }
}
