/// Corner radii. Cards and inputs share the same generous rounding so the
/// composer, cards, and sheets read as one family.
class AppRadii {
  const AppRadii._();

  /// Small controls: chips, status pills' inner elements, badges.
  static const double chip = 12;

  /// Buttons.
  static const double button = 18;

  /// Generic surfaces (dialogs, small panels).
  static const double global = 20;

  /// Cards and the composer.
  static const double card = 24;

  /// Text inputs.
  static const double input = 24;

  /// Bottom sheets.
  static const double sheet = 28;

  /// Fully rounded pills.
  static const double pill = 999;
}
