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
}
