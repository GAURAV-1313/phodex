import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Type system: Fraunces carries the app's personality in display/hero
/// moments (a characterful serif — deliberately not another "safe" grotesk),
/// IBM Plex Sans handles everyday UI text, and IBM Plex Mono renders code,
/// commands, and logs as one coherent family instead of the platform
/// monospace fallback.
///
/// There is exactly one size ladder, [AppTypeScale]; the Material
/// [TextTheme] built in [AppTypography.textTheme] is derived from it, so
/// `context.text.bodyLarge` and `AppTypeScale.body` can never disagree.
class AppTypeScale {
  const AppTypeScale._();
  static const double micro = 11; // eyebrow labels, tiny badges
  static const double caption = 13; // captions, timestamps, meta text
  static const double bodySmall = 15; // secondary body text
  static const double body = 17; // default reading size
  static const double subhead = 20; // emphasized body, list titles
  static const double title = 24; // card headlines, section titles
  static const double headline = 28; // screen section headers
  static const double displaySmall = 34; // in-context hero (cards, sheets)
  static const double displayLarge = 40; // full-screen hero headlines
}

class AppTypography {
  const AppTypography._();

  static TextStyle display({
    double fontSize = AppTypeScale.displaySmall,
    double? height,
    FontWeight fontWeight = FontWeight.w600,
    required Color color,
    double? letterSpacing,
  }) => GoogleFonts.fraunces(
    fontSize: fontSize,
    height: height,
    fontWeight: fontWeight,
    color: color,
    letterSpacing: letterSpacing,
  );

  static TextStyle sans({
    required double fontSize,
    required Color color,
    FontWeight fontWeight = FontWeight.w400,
    double? height,
    double? letterSpacing,
  }) => GoogleFonts.ibmPlexSans(
    fontSize: fontSize,
    height: height,
    fontWeight: fontWeight,
    color: color,
    letterSpacing: letterSpacing,
  );

  /// Builds the app's [TextTheme] from a concrete palette — called once per
  /// theme (light/dark) so each ends up with its own themed text colors
  /// instead of one static theme baked to light-mode colors.
  ///
  /// Slot mapping (Material name → ladder step):
  /// displayLarge 40 · displayMedium 34 · displaySmall 34 · headlineLarge 28
  /// · headlineMedium 28 · headlineSmall 24 · titleLarge 20 · titleMedium 17
  /// · titleSmall 15 · bodyLarge 17 · bodyMedium 15 · bodySmall 13 ·
  /// labelLarge 15 · labelMedium 13 · labelSmall 11.
  static TextTheme textTheme(AppColors colors) => TextTheme(
    displayLarge: display(
      fontSize: AppTypeScale.displayLarge,
      height: 1.05,
      letterSpacing: -0.8,
      color: colors.textPrimary,
    ),
    displayMedium: display(
      fontSize: AppTypeScale.displaySmall,
      height: 1.1,
      letterSpacing: -0.6,
      color: colors.textPrimary,
    ),
    displaySmall: display(
      fontSize: AppTypeScale.displaySmall,
      height: 40 / 34,
      letterSpacing: -0.5,
      color: colors.textPrimary,
    ),
    headlineLarge: display(
      fontSize: AppTypeScale.headline,
      height: 34 / 28,
      letterSpacing: -0.8,
      color: colors.textPrimary,
    ),
    headlineMedium: display(
      fontSize: AppTypeScale.headline,
      height: 34 / 28,
      letterSpacing: -0.6,
      color: colors.textPrimary,
    ),
    headlineSmall: sans(
      fontSize: AppTypeScale.title,
      height: 30 / 24,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.4,
      color: colors.textPrimary,
    ),
    titleLarge: sans(
      fontSize: AppTypeScale.subhead,
      height: 26 / 20,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.3,
      color: colors.textPrimary,
    ),
    titleMedium: sans(
      fontSize: AppTypeScale.body,
      height: 24 / 17,
      fontWeight: FontWeight.w600,
      color: colors.textPrimary,
    ),
    titleSmall: sans(
      fontSize: AppTypeScale.bodySmall,
      height: 20 / 15,
      fontWeight: FontWeight.w600,
      color: colors.textPrimary,
    ),
    bodyLarge: sans(
      fontSize: AppTypeScale.body,
      height: 25 / 17,
      color: colors.textPrimary,
    ),
    bodyMedium: sans(
      fontSize: AppTypeScale.bodySmall,
      height: 22 / 15,
      color: colors.textSecondary,
    ),
    bodySmall: sans(
      fontSize: AppTypeScale.caption,
      height: 18 / 13,
      color: colors.textSecondary,
    ),
    labelLarge: sans(
      fontSize: AppTypeScale.bodySmall,
      height: 20 / 15,
      fontWeight: FontWeight.w600,
      color: colors.textPrimary,
    ),
    labelMedium: sans(
      fontSize: AppTypeScale.caption,
      height: 18 / 13,
      fontWeight: FontWeight.w500,
      color: colors.textMuted,
    ),
    labelSmall: sans(
      fontSize: AppTypeScale.micro,
      height: 14 / 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
      color: colors.textMuted,
    ),
  );

  static TextStyle code({
    double fontSize = AppTypeScale.caption,
    required Color color,
    FontWeight fontWeight = FontWeight.w400,
  }) => GoogleFonts.ibmPlexMono(
    fontSize: fontSize,
    height: 18 / 13,
    color: color,
    fontWeight: fontWeight,
  );
}

/// Shorthand for the themed [TextTheme] — the standard way for widgets to
/// pick a text style instead of hand-writing `TextStyle(fontSize: …)`.
extension AppTextContext on BuildContext {
  TextTheme get text => Theme.of(this).textTheme;
}
