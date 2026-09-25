/// Corner radius tokens. Cards are generously rounded; controls less so,
/// so a button never looks like a card.
abstract final class AppRadii {
  /// Buttons, inputs, and small tiles.
  static const double control = 12;

  /// Stat tiles and inner panels.
  static const double tile = 16;

  /// Cards.
  static const double card = 20;

  /// Dialogs.
  static const double dialog = 24;

  /// Status pills.
  static const double chip = 999;

  /// Bottom sheets.
  static const double bottomSheet = 28;
}
