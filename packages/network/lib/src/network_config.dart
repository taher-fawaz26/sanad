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
  });

  final String baseUrl;

  /// Server-relative path used by [AuthInterceptor] to skip 401 handling
  /// and by [TokenManagerImpl] to call the refresh endpoint.
  final String refreshTokenPath;

  final Duration connectTimeout;
  final Duration receiveTimeout;

  // No `sendTimeout` — Dio's send-phase timeout fires while the request
  // body is still uploading and is a known source of false timeouts on
  // POST/PATCH (the server can finish and return 2xx after Dio has already
  // aborted the socket). `connectTimeout` + `receiveTimeout` are sufficient
  // to bound a hung request.
  BaseOptions get dioBaseOptions => BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: connectTimeout,
    receiveTimeout: receiveTimeout,
  );
}
