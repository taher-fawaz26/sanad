/// How a sheet's resting height is determined before any nested-sheet morph.
enum SheetSize {
  /// Wraps the sheet's content — bounded below by
  /// `SheetRouteSettings.minHeight` and above by
  /// `SheetRouteSettings.maxHeightFactor` of the screen height.
  /// Matches Apple's action sheets / LinkedIn's small menus: no empty space
  /// below short content.
  content,

  /// Fills `SheetRouteSettings.initialHeightFraction` (or the largest
  /// `snapFractions` entry) of the screen, regardless of content size. Use
  /// for long forms — OTP, search, multi-step flows, large settings.
  expanded,
}
