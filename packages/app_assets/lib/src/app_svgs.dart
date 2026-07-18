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

  /// Red map pin marker — Figma location / coverage map pin.
  static const String mapPinMarker = '$_base/map_pin_marker.svg';

  /// Teal radius ring overlay — Figma coverage map ellipse.
  static const String mapRadiusRing = '$_base/map_radius_ring.svg';

  /// UAE flag — phone field country prefix.
  static const String flagAe = '$_base/flag_ae.svg';

  /// Chevron down — select / dropdown fields.
  static const String chevronDown = '$_base/chevron_down.svg';

  /// Close (X) — modal / form dismiss.
  static const String close = '$_base/close.svg';

  /// Trash / delete — list row remove action.
  static const String trash = '$_base/trash.svg';

  /// Bold trash — destructive action rows (e.g. branch actions sheet).
  static const String trashBold = '$_base/trash_bold.svg';

  // ── Branch actions bottom sheet ────────────────────────────────────────────

  /// Store / branch — header icon on white background.
  static const String branchStore = '$_base/branch_store.svg';

  /// View branch — expand / focus icon.
  static const String branchView = '$_base/branch_view.svg';

  /// Set under maintenance — settings gear icon.
  static const String branchMaintenance = '$_base/branch_maintenance.svg';

  /// Edit branch — pencil icon.
  static const String branchEdit = '$_base/branch_edit.svg';

  // ── Branches / maps / pickers ─────────────────────────────────────────────

  /// Map pin outline — location permission / location empty states.
  static const String mapPinOutline = '$_base/map_pin_outline.svg';

  /// Map pin with plus — coverage add-area chip.
  static const String mapPinAdd = '$_base/map_pin_add.svg';

  /// Users group — team search empty state.
  static const String users2 = '$_base/users_2.svg';

  /// Search with alert — service search empty state.
  static const String searchAlert = '$_base/search_alert.svg';

  /// Circle X — search field clear affordance.
  static const String xCircle = '$_base/x_circle.svg';
}
