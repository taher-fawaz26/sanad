import 'package:app_assets/app_assets.dart';

/// Every Lottie animation shipped with the app, mapped to its asset path.
///
/// Backed by the path constants in `package:app_assets`'s `AppAnimations` —
/// this enum is the only place outside `app_assets` allowed to reference
/// them; everything else goes through `AppLottie`.
enum AppLottieAsset {
  /// SANAD green fading-ring spinner — app-wide loading indicator.
  loading(AppAnimations.appLoadingIndicator),

  /// SANAD green/gold orb — document-extraction loading state.
  documentExtraction(AppAnimations.documentExtractionLoader),

  /// "404 Not Found" line-art illustration.
  notFound(AppAnimations.notFound404),

  /// "403 Forbidden" illustration.
  forbidden(AppAnimations.forbidden403),

  /// AI chat's animated center visual — the "Sanad is here" mark on Home.
  aiAssistant(AppAnimations.aiAssistantLoading)
  ;

  const AppLottieAsset(this.path);

  /// Asset path, relative to `package:app_assets`.
  final String path;
}
