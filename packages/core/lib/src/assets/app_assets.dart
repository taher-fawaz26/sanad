/// Root asset registry for the Sanad monorepo.
///
/// Physical files live under `packages/core/assets/`. Flutter packages that
/// load them must list those paths under `flutter.assets` (see design_system).
abstract final class AppAssets {
  AppAssets._();

  /// Package directory that owns the asset files on disk.
  static const String package = 'core';
}
