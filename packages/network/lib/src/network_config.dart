import 'package:dio/dio.dart';
import 'package:network/network.dart' show AuthInterceptor, TokenManagerImpl;

/// Immutable configuration for the Dio HTTP clients.
///
/// Apps construct this in their bootstrap and pass it to `SandNetworkModule`
/// or directly to `DioFactory`. This keeps API URLs and timeout values
/// out of the network package and makes them configurable per-environment.
class NetworkConfig {
  const NetworkConfig({
    required this.baseUrl,
    required this.refreshTokenPath,
    this.connectTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 15),
    this.sendTimeout = const Duration(seconds: 15),
  });

  final String baseUrl;

  /// Server-relative path used by [AuthInterceptor] to skip 401 handling
  /// and by [TokenManagerImpl] to call the refresh endpoint.
  final String refreshTokenPath;

  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Duration sendTimeout;

  BaseOptions get dioBaseOptions => BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: connectTimeout,
    receiveTimeout: receiveTimeout,
    sendTimeout: sendTimeout,
  );
}
