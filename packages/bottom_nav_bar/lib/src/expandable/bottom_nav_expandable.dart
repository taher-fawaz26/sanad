/// Internal expandable menu contract — hides implementation details.
abstract class BottomNavExpandable {
  /// Whether the center menu is expanded.
  bool get isExpanded;

  /// Opens the center menu.
  void expand();

  /// Closes the center menu.
  void collapse();

  /// Toggles the center menu.
  void toggle();
}
