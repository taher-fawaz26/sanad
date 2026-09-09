/// The public service catalogue the draft composer picks from.
///
/// Read-only. `apps/sanad_provider/packages/services` reads the same two
/// endpoints, but that package is provider-local and entangled with
/// provider-services and moderation, so it cannot be imported here. Only these
/// two calls are duplicated; if a third consumer appears, extract a shared
/// `catalogue` package rather than copying again.
abstract final class CatalogueApiPaths {
  CatalogueApiPaths._();

  /// `GET` — catalogue services. `serviceId` on a draft comes from here.
  static const String services = 'services';

  /// `GET` — catalogue categories, for grouping the picker.
  static const String categories = 'categories';
}
