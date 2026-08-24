/// Backend endpoint for the provider dashboard statistic cards.
abstract final class ProviderStatisticsApiPaths {
  ProviderStatisticsApiPaths._();

  /// `GET` — one card per statistic the caller holds permission for.
  static const String statistics = 'service-provider/statistics';
}
