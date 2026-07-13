import 'dart:async';

import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:network/network.dart' show TimeoutErrorInterceptor;
import 'package:network/src/interceptors/timeout_error_interceptor.dart' show TimeoutErrorInterceptor;

/// Retries once on connect/send/receive timeouts with exponential backoff.
/// Register BEFORE [TimeoutErrorInterceptor] in [Dio.interceptors].
class RetryOnTimeoutInterceptor extends Interceptor {
  RetryOnTimeoutInterceptor({
    required Dio dio,
    this.maxRetries = 1,
    this.baseDelay = AppDurations.dioRetryBaseDelay,
  }) : _dio = dio;

  final Dio _dio;
  final int maxRetries;
  final Duration baseDelay;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!_isTimeout(err)) {
      handler.next(err);
      return;
    }
    final options = err.requestOptions;
    final attempt =
        (options.extra[StorageKeys.dioTimeoutRetryCount] as int?) ?? 0;
    if (attempt >= maxRetries) {
      handler.next(err);
      return;
    }
    options.extra[StorageKeys.dioTimeoutRetryCount] = attempt + 1;
    final delayMs = baseDelay.inMilliseconds * (1 << attempt);
    unawaited(_retry(options, handler, delayMs));
  }

  Future<void> _retry(
    RequestOptions options,
    ErrorInterceptorHandler handler,
    int delayMs,
  ) async {
    await Future<void>.delayed(Duration(milliseconds: delayMs));
    try {
      handler.resolve(await _dio.fetch(options));
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  static bool _isTimeout(DioException e) =>
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.sendTimeout ||
      e.type == DioExceptionType.receiveTimeout;
}
