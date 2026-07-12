/// Shared raster image asset paths shipped under
/// `packages/app_assets/assets/images/`.
///
/// Load with `Image.asset(AppImages.x, package: AppAssets.package)`.
abstract final class AppImages {
  AppImages._();

  static const String _base = 'assets/images';

  /// Figma `empty states / internet` (`321:8297`) — no network connection.
  static const String networkFailure = '$_base/empty_states/network_failure.png';

  /// Figma `empty states / No branches yet` (`328:9898`) — generic empty.
  static const String emptyState = '$_base/empty_states/empty_state.png';
}
