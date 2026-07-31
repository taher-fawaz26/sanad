/// i18n key constants for network-layer errors.
/// Resolve via EasyLocalization in the presentation layer.
abstract final class ErrorMessages {
  ErrorMessages._();

  static const String noInternet = 'errors.no_internet';
  static const String timeout = 'errors.timeout';
  static const String serverError = 'errors.server_error';
  static const String unknown = 'errors.unknown';
  static const String unauthorized = 'errors.unauthorized';
  static const String notFound = 'errors.not_found';
  static const String badRequest = 'errors.bad_request';
  static const String requestCancelled = 'errors.request_cancelled';
  static const String connectionReset = 'errors.connection_reset';
  static const String secureConnectionFailed =
      'errors.secure_connection_failed';
  static const String invalidCredentials = 'errors.invalid_credentials';
  static const String cacheError = 'errors.cache_error';
}
