import 'dart:async';
import 'dart:math';

import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:network/network.dart' show TimeoutErrorInterceptor;
import 'package:network/src/interceptors/timeout_error_interceptor.dart'
    show TimeoutErrorInterceptor;

/// Retries connect/send/receive timeouts with exponential backoff + jitter.
/// Register BEFORE [TimeoutErrorInterceptor] in [Dio.interceptors].
///
/// Only retries *idempotent* HTTP methods (GET/HEAD/PUT/DELETE/OPTIONS).
/// POST/PATCH are never auto-retried on a timeout: the server may have
/// already received and processed the original attempt (a slow response is
/// not proof the request failed), so blindly re-firing a create/update risks
/// silently duplicating it.
class RetryOnTimeoutInterceptor extends Interceptor {
  RetryOnTimeoutInterceptor({
    required Dio dio,
    this.maxRetries = 2,
    this.baseDelay = AppDurations.dioRetryBaseDelay,
    this.maxJitter = const Duration(milliseconds: 200),
    Random? random,
  }) : _dio = dio,
       _random = random ?? Random();

  final Dio _dio;
  final int maxRetries;
  final Duration baseDelay;

  /// Upper bound of the random jitter added to each backoff to avoid
  /// thundering-herd retries. Set to [Duration.zero] to disable (tests).
  final Duration maxJitter;
  final Random _random;

  /// Backoff for a given zero-based [attempt]: `baseDelay * 2^attempt` plus
  /// random jitter in `[0, maxJitter]`. Exposed for testing.
  Duration backoffFor(int attempt) {
    final backoffMs = baseDelay.inMilliseconds * (1 << attempt);
    final jitterMs = maxJitter.inMilliseconds > 0
        ? _random.nextInt(maxJitter.inMilliseconds + 1)
        : 0;
    return Duration(milliseconds: backoffMs + jitterMs);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!_isTimeout(err) || !_isIdempotent(err.requestOptions.method)) {
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
    unawaited(_retry(options, handler, backoffFor(attempt)));
  }

  Future<void> _retry(
    RequestOptions options,
    ErrorInterceptorHandler handler,
    Duration delay,
  ) async {
    await Future<void>.delayed(delay);
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

  /// GET/HEAD/PUT/DELETE/OPTIONS are safe to blindly retry — repeating them
  /// has no additional side effect. POST/PATCH are not: the server may have
  /// already acted on the original attempt.
  static bool _isIdempotent(String method) => const {
    'GET',
    'HEAD',
    'PUT',
    'DELETE',
    'OPTIONS',
  }.contains(method.toUpperCase());
}
