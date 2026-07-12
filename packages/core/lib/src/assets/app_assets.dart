/// Root asset registry for the Sanad monorepo.
///
/// Physical files live under `packages/core/assets/`. Load them with
/// `SvgPicture.asset(AppSvgs.x, package: AppAssets.package)`.
abstract final class AppAssets {
  AppAssets._();

  /// Flutter package that owns the asset files.
  static const String package = 'core';
}
