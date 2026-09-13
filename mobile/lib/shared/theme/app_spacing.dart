/// The spacing ladder. Every gap, padding, and inset in the app should be
/// one of these — never an arbitrary number — so rhythm stays consistent
/// from screen to screen.
class AppSpacing {
  const AppSpacing._();

  static const double s2 = 2;
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s40 = 40;
  static const double s48 = 48;

  /// Horizontal inset of every screen's content.
  static const double screen = 24;

  /// Vertical inset between the safe area and a screen's header.
  static const double screenTop = 16;
}
