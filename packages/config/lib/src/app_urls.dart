import 'package:meta/meta.dart';

/// API base URLs and service endpoints for a given environment.
@immutable
class AppUrls {
  /// Creates an [AppUrls] instance with the required and optional URL fields.
  const AppUrls({
    required this.apiBaseUrl,
    required this.refreshTokenPath,
    this.socketBaseUrl,
    this.cdnBaseUrl,
  });

  /// The base URL for all REST API requests.
  final String apiBaseUrl;

  /// The path appended to [apiBaseUrl] when refreshing an access token.
  final String refreshTokenPath;

  /// The base URL for WebSocket connections, if any.
  final String? socketBaseUrl;

  /// The base URL for CDN-hosted assets, if any.
  final String? cdnBaseUrl;
}
