/// Shared raster image asset paths shipped under
/// `packages/app_assets/assets/images/`.
///
/// Load with `Image.asset(AppImages.x, package: AppAssets.package)`.
abstract final class AppImages {
  AppImages._();

  static const String _base = 'assets/images';

  /// Figma `empty states / internet` (`321:8297`) — no network connection.
  static const String networkFailure =
      '$_base/empty_states/network_failure.png';

  /// Figma `empty states / No branches yet` (`328:9898`) — generic empty.
  static const String emptyState = '$_base/empty_states/empty_state.png';

  /// Figma `empty states / No branch locations` (`347:13862`).
  static const String noBranchLocations =
      '$_base/branches/no_branch_locations.png';

  /// Figma add-branch workers empty state (`245:6400`).
  static const String addWorkers = '$_base/workers/worker.png';

  /// Wrench & screwdriver — services empty state (`347:13959`).
  static const String serviceTools = '$_base/services/service_tools.png';

  static const String addServices = '$_base/illustrations/add_services.svg';
}
