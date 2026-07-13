/// SVG asset paths shipped under `packages/app_assets/assets/svgs/`.
///
/// Load with `AppSvgPicture.asset(AppSvgs.x)` from `design_system`, or
/// `SvgPicture.asset(AppSvgs.x, package: AppAssets.package)`.
abstract final class AppSvgs {
  AppSvgs._();

  static const String _base = 'assets/svgs';

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

  // ── Header / actions ───────────────────────────────────────────────────────

  /// Notification bell — header icon (unread dot rendered in Flutter).
  static const String notification = '$_base/notification.svg';

  // ── Search bar ─────────────────────────────────────────────────────────────

  /// Magnifying glass — Figma `Bars / Search Bars` leading icon.
  static const String search = '$_base/search.svg';

  /// Microphone — Figma `Bars / Search Bars` trailing icon.
  static const String mic = '$_base/mic.svg';

  // ── Form fields ────────────────────────────────────────────────────────────

  /// Map / location — branch location field leading icon.
  static const String map = '$_base/map.svg';

  /// UAE flag — phone field country prefix.
  static const String flagAe = '$_base/flag_ae.svg';

  /// Chevron down — select / dropdown fields.
  static const String chevronDown = '$_base/chevron_down.svg';

  /// Close (X) — modal / form dismiss.
  static const String close = '$_base/close.svg';
}
