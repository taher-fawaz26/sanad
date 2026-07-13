/// App-specific raster images for `sanad_provider`, under
/// `apps/sanad_provider/assets/images/`.
abstract final class ProviderImages {
  ProviderImages._();

  static const String _base = 'assets/images';

  /// Figma `empty states / No search results` (`322:9661`).
  static const String noResults = '$_base/branches/noresults.png';

  /// Figma `empty states / Branch with no team` (`321:8319`).
  static const String worker = '$_base/workers/worker.png';
}
