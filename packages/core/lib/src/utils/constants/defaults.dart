abstract final class AppDefaults {
  AppDefaults._();

  static const int paginationPageSize = 20;
  static const int maxRetryAttempts = 3;
  static const Duration httpTimeout = Duration(seconds: 30);
  static const Duration httpConnectTimeout = Duration(seconds: 15);
}
