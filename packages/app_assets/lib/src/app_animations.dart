/// Lottie animation asset paths shipped under
/// `packages/app_assets/assets/animations/production/`.
///
/// Load with `Lottie.asset(AppAnimations.x, package: AppAssets.package)`.
///
/// The unrecolored source files these are derived from live under
/// `assets/animations/source/` for reference only — not bundled as app
/// assets.
abstract final class AppAnimations {
  AppAnimations._();

  static const String _base = 'assets/animations/production';

  /// SANAD green/gold orb — document extraction loading state.
  static const String documentExtractionLoader =
      '$_base/document_extraction_loader.json';

  /// SANAD green fading-ring spinner — app-wide `AppLoadingIndicator`.
  static const String appLoadingIndicator =
      '$_base/app_loading_indicator.json';

  /// "404 Not Found" line-art animation, recolored to the SANAD brand teal
  /// (`MainPalette.shade700`) — used by `AppNotFoundPage`.
  static const String notFound404 = '$_base/not_found_404.json';

  /// "403 Forbidden" dinosaur-hatching animation, recolored to the SANAD
  /// palette (brand teal + red danger accents) — used by `AppForbiddenPage`.
  static const String forbidden403 = '$_base/forbidden_403.json';
}
