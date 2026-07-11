/// SVG asset paths shipped under `packages/core/assets/svgs/`.
///
/// Paths use the `packages/core/...` form so Flutter consumers can load them
/// after declaring the same paths in their `flutter.assets` section.
abstract final class AppSvgs {
  AppSvgs._();

  static const String _base = 'packages/core/assets/svgs';

  // ── Featured icons ─────────────────────────────────────────────────────────

  /// Lightning bolt — featured icon primary / gray default.
  static const String zap = '$_base/zap.svg';

  /// Alert circle — featured icon error default.
  static const String alertCircle = '$_base/alert_circle.svg';

  /// Alert triangle — featured icon warning default.
  static const String alertTriangle = '$_base/alert_triangle.svg';

  /// Check circle — featured icon success default.
  static const String checkCircle = '$_base/check_circle.svg';

  // ── Bottom navigation ──────────────────────────────────────────────────────

  /// Home tab.
  static const String navHome = '$_base/nav_home.svg';

  /// Requests tab.
  static const String navRequest = '$_base/nav_request.svg';

  /// Messages tab.
  static const String navMessage = '$_base/nav_message.svg';

  /// Settings tab.
  static const String navSettings = '$_base/nav_settings.svg';
}
