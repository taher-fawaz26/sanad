import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network/src/interceptors/retry_on_timeout_interceptor.dart';

void main() {
  group('RetryOnTimeoutInterceptor.backoffFor', () {
    test('is exponential in the base delay with jitter disabled', () {
      final interceptor = RetryOnTimeoutInterceptor(
        dio: Dio(),
        baseDelay: const Duration(milliseconds: 400),
        maxJitter: Duration.zero,
      );

      expect(interceptor.backoffFor(0), const Duration(milliseconds: 400));
      expect(interceptor.backoffFor(1), const Duration(milliseconds: 800));
      expect(interceptor.backoffFor(2), const Duration(milliseconds: 1600));
    });

    test('adds bounded jitter on top of the exponential backoff', () {
      final interceptor = RetryOnTimeoutInterceptor(
        dio: Dio(),
        baseDelay: const Duration(milliseconds: 400),
        maxJitter: const Duration(milliseconds: 200),
        random: Random(1),
      );

      final delay = interceptor.backoffFor(0).inMilliseconds;
      expect(delay, greaterThanOrEqualTo(400));
      expect(delay, lessThanOrEqualTo(600));
    });

    test('defaults to more than one retry attempt', () {
      expect(RetryOnTimeoutInterceptor(dio: Dio()).maxRetries, greaterThan(1));
    });
  });
}
