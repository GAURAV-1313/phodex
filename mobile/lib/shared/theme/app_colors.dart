import 'package:flutter/material.dart';

/// The app's color palette, as a [ThemeExtension] so light and dark mode can
/// each supply their own concrete values instead of every screen reaching
/// for fixed, theme-blind static constants. Look it up via `context.colors`
/// (see [AppColorsContext] below) anywhere a [BuildContext] is available.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bgPrimary,
    required this.bgSurface,
    required this.bgCard,
    required this.bgInput,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.borderSubtle,
    required this.accentPrimary,
    required this.accentPrimaryDeep,
    required this.accentPrimarySoft,
    required this.accentSuccess,
    required this.accentWarning,
    required this.accentError,
    required this.mascotBody,
    required this.mascotBodyDark,
    required this.mascotBreast,
    required this.mascotBeak,
    required this.mascotFace,
    required this.mascotEye,
  });

  final Color bgPrimary;
  final Color bgSurface;
  final Color bgCard;
  final Color bgInput;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  final Color borderSubtle;

  // Vivid indigo — the app's signature color. Chosen to read as
  // "intelligent" and stand apart from the warm cream ground, rather than
  // the platform-default iOS blue this replaced.
  final Color accentPrimary;
  final Color accentPrimaryDeep;
  final Color accentPrimarySoft;

  final Color accentSuccess;
  final Color accentWarning;
  final Color accentError;

  // Mascot palette — an original robin (the bird), not any copyrighted
  // character. Kept separate so it can be recolored independently of
  // interactive UI accents.
  final Color mascotBody;
  final Color mascotBodyDark;
  final Color mascotBreast;
  final Color mascotBeak;
  final Color mascotFace;
  final Color mascotEye;

  /// Tracks this instance's own [accentPrimary] rather than existing as a
  /// separately-lerped field.
  Color get mascotAccent => accentPrimary;

  /// The app's warm-cream-plus-indigo light theme.
  static const light = AppColors(
    bgPrimary: Color(0xFFFBF9F7),
    bgSurface: Color(0xFFFFFFFF),
    bgCard: Color(0xFFFFFFFF),
    bgInput: Color(0xFFF5F3EF),
    textPrimary: Color(0xFF1D1A22),
    textSecondary: Color(0xFF67616F),
    textMuted: Color(0xFF96909C),
    borderSubtle: Color(0xFFEAE6E9),
    accentPrimary: Color(0xFF5B4FE8),
    accentPrimaryDeep: Color(0xFF433AC4),
    accentPrimarySoft: Color(0xFFEEECFC),
    accentSuccess: Color(0xFF16A34A),
    accentWarning: Color(0xFFD97706),
    accentError: Color(0xFFDC2626),
    mascotBody: Color(0xFF463222),
    mascotBodyDark: Color(0xFF362619),
    mascotBreast: Color(0xFFE2572B),
    mascotBeak: Color(0xFFF4A93E),
    mascotFace: Color(0xFFFBF9F7),
    mascotEye: Color(0xFF241A12),
  );

  /// The dark counterpart — deliberately designed to mirror the light
  /// theme's warm-cream-plus-indigo character rather than defaulting to a
  /// generic Material dark palette.
  static const dark = AppColors(
    bgPrimary: Color(0xFF17151C),
    bgSurface: Color(0xFF1D1B24),
    bgCard: Color(0xFF221F2A),
    bgInput: Color(0xFF28242F),
    textPrimary: Color(0xFFF5F3F7),
    textSecondary: Color(0xFFA79FB0),
    textMuted: Color(0xFF716A7D),
    borderSubtle: Color(0xFF322D3B),
    accentPrimary: Color(0xFF8B7FFF),
    accentPrimaryDeep: Color(0xFF6C5FE0),
    accentPrimarySoft: Color(0xFF2C2650),
    accentSuccess: Color(0xFF34D399),
    accentWarning: Color(0xFFF3A73F),
    accentError: Color(0xFFF16565),
    mascotBody: Color(0xFF463222),
    mascotBodyDark: Color(0xFF362619),
    mascotBreast: Color(0xFFE2572B),
    mascotBeak: Color(0xFFF4A93E),
    mascotFace: Color(0xFF17151C),
    mascotEye: Color(0xFF241A12),
  );

  @override
  AppColors copyWith({
    Color? bgPrimary,
    Color? bgSurface,
    Color? bgCard,
    Color? bgInput,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? borderSubtle,
    Color? accentPrimary,
    Color? accentPrimaryDeep,
    Color? accentPrimarySoft,
    Color? accentSuccess,
    Color? accentWarning,
    Color? accentError,
    Color? mascotBody,
    Color? mascotBodyDark,
    Color? mascotBreast,
    Color? mascotBeak,
    Color? mascotFace,
    Color? mascotEye,
  }) {
    return AppColors(
      bgPrimary: bgPrimary ?? this.bgPrimary,
      bgSurface: bgSurface ?? this.bgSurface,
      bgCard: bgCard ?? this.bgCard,
      bgInput: bgInput ?? this.bgInput,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      accentPrimary: accentPrimary ?? this.accentPrimary,
      accentPrimaryDeep: accentPrimaryDeep ?? this.accentPrimaryDeep,
      accentPrimarySoft: accentPrimarySoft ?? this.accentPrimarySoft,
      accentSuccess: accentSuccess ?? this.accentSuccess,
      accentWarning: accentWarning ?? this.accentWarning,
      accentError: accentError ?? this.accentError,
      mascotBody: mascotBody ?? this.mascotBody,
      mascotBodyDark: mascotBodyDark ?? this.mascotBodyDark,
      mascotBreast: mascotBreast ?? this.mascotBreast,
      mascotBeak: mascotBeak ?? this.mascotBeak,
      mascotFace: mascotFace ?? this.mascotFace,
      mascotEye: mascotEye ?? this.mascotEye,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      bgPrimary: Color.lerp(bgPrimary, other.bgPrimary, t)!,
      bgSurface: Color.lerp(bgSurface, other.bgSurface, t)!,
      bgCard: Color.lerp(bgCard, other.bgCard, t)!,
      bgInput: Color.lerp(bgInput, other.bgInput, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      accentPrimary: Color.lerp(accentPrimary, other.accentPrimary, t)!,
      accentPrimaryDeep: Color.lerp(
        accentPrimaryDeep,
        other.accentPrimaryDeep,
        t,
      )!,
      accentPrimarySoft: Color.lerp(
        accentPrimarySoft,
        other.accentPrimarySoft,
        t,
      )!,
      accentSuccess: Color.lerp(accentSuccess, other.accentSuccess, t)!,
      accentWarning: Color.lerp(accentWarning, other.accentWarning, t)!,
      accentError: Color.lerp(accentError, other.accentError, t)!,
      mascotBody: Color.lerp(mascotBody, other.mascotBody, t)!,
      mascotBodyDark: Color.lerp(mascotBodyDark, other.mascotBodyDark, t)!,
      mascotBreast: Color.lerp(mascotBreast, other.mascotBreast, t)!,
      mascotBeak: Color.lerp(mascotBeak, other.mascotBeak, t)!,
      mascotFace: Color.lerp(mascotFace, other.mascotFace, t)!,
      mascotEye: Color.lerp(mascotEye, other.mascotEye, t)!,
    );
  }
}

/// Looks up the active theme's [AppColors] palette — the standard way for
/// widgets to read themed colors instead of a fixed static constant.
extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
