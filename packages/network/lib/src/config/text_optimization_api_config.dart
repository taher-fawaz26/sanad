/// Configuration for the third-party "Enhance with AI" text-optimization
/// service (SAN-578).
///
/// Unlike `NetworkConfig`, this is a single fixed external host — it does not
/// vary per app environment (`ENV` dart-define) and carries no auth: the
/// contract requires no bearer token, so this client is deliberately wired
/// without `AuthInterceptor` (see `NetworkDI.init`) to avoid leaking the
/// user's session token to a third party.
abstract final class TextOptimizationApiConfig {
  TextOptimizationApiConfig._();

  static const baseUrl = 'https://intake.drlawyer.ae';
  static const optimizePath = '/api/v1/optimize';
  static const connectTimeout = Duration(seconds: 15);
  static const receiveTimeout = Duration(seconds: 15);
}
