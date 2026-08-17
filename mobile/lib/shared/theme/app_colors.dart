import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const bgPrimary = Color(0xFFFBF9F7);
  static const bgSurface = Color(0xFFFFFFFF);
  static const bgCard = Color(0xFFFFFFFF);
  static const bgInput = Color(0xFFF5F3EF);

  static const textPrimary = Color(0xFF1D1A22);
  static const textSecondary = Color(0xFF67616F);
  static const textMuted = Color(0xFF96909C);

  static const borderSubtle = Color(0xFFEAE6E9);

  // Vivid indigo — the app's signature color. Chosen to read as
  // "intelligent" and stand apart from the warm cream ground, rather than
  // the platform-default iOS blue this replaced.
  static const accentPrimary = Color(0xFF5B4FE8);
  static const accentPrimaryDeep = Color(0xFF433AC4);
  static const accentPrimarySoft = Color(0xFFEEECFC);

  static const accentSuccess = Color(0xFF16A34A);
  static const accentWarning = Color(0xFFD97706);
  static const accentError = Color(0xFFDC2626);

  // Mascot palette — an original robin (the bird), not any copyrighted
  // character. Kept separate so it can be recolored independently of
  // interactive UI accents.
  static const mascotBody = Color(0xFF463222);
  static const mascotBodyDark = Color(0xFF362619);
  static const mascotBreast = Color(0xFFE2572B);
  static const mascotBeak = Color(0xFFF4A93E);
  static const mascotFace = Color(0xFFFBF9F7);
  static const mascotEye = Color(0xFF241A12);
  static const mascotAccent = accentPrimary;
}
