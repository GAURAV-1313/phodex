import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Type system: Fraunces carries the app's personality in display/hero
/// moments (a characterful serif — deliberately not another "safe" grotesk),
/// IBM Plex Sans handles everyday UI text, and IBM Plex Mono renders code,
/// commands, and logs as one coherent family instead of the platform
/// monospace fallback.
/// The app's type scale — one deliberate ladder of sizes instead of each
/// screen picking arbitrary pixel values. Roughly a 1.15–1.2 ratio, snapped
/// to round numbers.
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
    double fontSize = 34,
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

  /// Builds the app's [TextTheme] from a concrete palette — called once per
  /// theme (light/dark) so each ends up with its own themed text colors
  /// instead of one static theme baked to light-mode colors.
  static TextTheme textTheme(AppColors colors) => TextTheme(
    displaySmall: GoogleFonts.fraunces(
      fontSize: 34,
      height: 40 / 34,
      fontWeight: FontWeight.w600,
      color: colors.textPrimary,
    ),
    headlineMedium: GoogleFonts.fraunces(
      fontSize: 28,
      height: 34 / 28,
      fontWeight: FontWeight.w600,
      color: colors.textPrimary,
    ),
    headlineSmall: GoogleFonts.ibmPlexSans(
      fontSize: 22,
      height: 28 / 22,
      fontWeight: FontWeight.w600,
      color: colors.textPrimary,
    ),
    bodyLarge: GoogleFonts.ibmPlexSans(
      fontSize: 16,
      height: 24 / 16,
      fontWeight: FontWeight.w400,
      color: colors.textPrimary,
    ),
    bodyMedium: GoogleFonts.ibmPlexSans(
      fontSize: 15,
      height: 22 / 15,
      fontWeight: FontWeight.w400,
      color: colors.textSecondary,
    ),
    labelMedium: GoogleFonts.ibmPlexSans(
      fontSize: 13,
      height: 18 / 13,
      fontWeight: FontWeight.w500,
      color: colors.textMuted,
    ),
  );

  static TextStyle code({
    double fontSize = 13,
    required Color color,
    FontWeight fontWeight = FontWeight.w400,
  }) => GoogleFonts.ibmPlexMono(
    fontSize: fontSize,
    height: 18 / 13,
    color: color,
    fontWeight: fontWeight,
  );
}
