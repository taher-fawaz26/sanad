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
  static const String appLoadingIndicator = '$_base/app_loading_indicator.json';

  /// "404 Not Found" line-art animation, recolored to the SANAD brand teal
  /// (`MainPalette.shade700`) — used by `AppNotFoundPage`.
  static const String notFound404 = '$_base/not_found_404.json';

  /// "403 Forbidden" dinosaur-hatching animation, recolored to the SANAD
  /// palette (brand teal + red danger accents) — used by `AppForbiddenPage`.
  static const String forbidden403 = '$_base/forbidden_403.json';

  /// AI chat's animated center visual (Figma `7118:29597`, "Chat – 01 Home").
  ///
  /// A **self-contained vector** export (shape layers only, zero image
  /// assets), so it renders from this file alone.
  ///
  /// That property is the whole point, and is why this is not the
  /// LottieFiles-authored export of the same mark. That export
  /// (`source/ai_assistant_hero_image_based.json`, kept for reference) draws
  /// everything through two `ty:2` image layers pointing at eight PNGs under
  /// `"u":"/i/"`, and its only other layer is a precomp with `"layers":[]`.
  /// Without that image package it has literally nothing to draw, so it
  /// rendered an empty box no matter how correctly it was wired — which is
  /// exactly what it did here for several iterations. If the `/i/` PNGs are
  /// ever added to this package, that file can replace this one in place; a
  /// vector re-export is the better fix.
  static const String aiAssistantLoading = '$_base/ai_assistant_loading.json';
}
