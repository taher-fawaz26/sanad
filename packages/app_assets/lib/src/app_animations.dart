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

  /// AI chat's animated center visual — the green bloom behind Sanad's mark
  /// on Home (Figma `Chat - 01 Home`, `7118:29598`).
  ///
  /// A rotating aura ring behind an orb that fades up, looping every 5s
  /// (512 square, 30fps, 150 frames). Built from the supplied dotLottie kept
  /// beside it at `source/ai_assistant_hero.lottie`.
  ///
  /// **Self-contained.** This animation draws through image layers rather
  /// than shapes, and it previously painted an empty box here because those
  /// images were not in this package. They are now recoloured and embedded
  /// in the composition as `data:image/webp;base64` asset sources
  /// (`"e": 1`), so it renders from this file alone — no `/i/` folder, and
  /// no dependence on `LottieComposition.decodeZip`, whose `.lottie`
  /// handling picks the first `.json` in the archive (the manifest) and
  /// resolves image paths that this export's leading-slash `"u": "/i/"`
  /// does not match.
  ///
  /// **Recoloured, not redrawn.** Its artwork shipped violet; every pixel's
  /// hue was mapped onto Figma's own bloom gradient hues for this node
  /// (`#30C9A9` `main/500` at the ring's cool end, `#87FC00` `accent/200` at
  /// its warm end), preserving saturation, value and alpha — so the motion,
  /// timing, easing, loop, opacity ramps and soft falloff are the source
  /// file's, untouched. Six image assets the composition never references
  /// were dropped; no layer or keyframe was.
  ///
  /// The Sanad mark is **not** in this file — it is a bloom only. The white
  /// sparkle and its dark-teal check ride on top from
  /// `AppSvgs.aiChatHeroMark`; see `_AiCenterVisual` in `ai_chat_page.dart`.
  static const String aiAssistantLoading = '$_base/ai_assistant_loading.json';
}
