/// Configuration for the "Enhance with AI" text-optimization endpoint.
///
/// The endpoint (`POST /api/v1/agent/enhance-text`) lives on the Sanad backend
/// and requires authentication, so — unlike the previous third-party host — it
/// is served over the app's own base URL (`NetworkConfig.baseUrl`) through an
/// authenticated Dio that carries the session bearer token via
/// `AuthInterceptor` (see `NetworkDI.init`).
///
/// Only the path and timeouts are fixed here; the base URL and auth come from
/// the shared network stack. The path is **base-URL-relative** (no leading
/// slash, no `/api/v1` prefix), matching every other endpoint constant in the
/// project — `NetworkConfig.baseUrl` already ends in `/api/v1/`, so Dio
/// composes the full `.../api/v1/agent/enhance-text`. A leading `/api/v1`
/// here would double the prefix (`/api/v1/api/v1/...` → 404). The receive
/// timeout is deliberately long: an AI
/// enhancement can take up to ~2 minutes on success and ~4 minutes before a
/// failure, far beyond the 15s default used by every other request. Scoping
/// the long timeout to this dedicated client keeps unrelated APIs bounded by
/// the normal `NetworkConfig` timeouts.
abstract final class TextOptimizationApiConfig {
  TextOptimizationApiConfig._();

  static const enhanceTextPath = 'agent/enhance-text';
  static const connectTimeout = Duration(seconds: 15);
  static const receiveTimeout = Duration(minutes: 5);
}
