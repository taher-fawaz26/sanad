import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network/src/interceptors/retry_on_timeout_interceptor.dart';

void main() {
  group('RetryOnTimeoutInterceptor.onError', () {
    late Dio dio;
    late _StageableAdapter adapter;

    setUp(() {
      dio = Dio();
      adapter = _StageableAdapter();
      dio.httpClientAdapter = adapter;
      dio.interceptors.add(
        RetryOnTimeoutInterceptor(
          dio: dio,
          baseDelay: Duration.zero,
          maxJitter: Duration.zero,
        ),
      );
    });

    test('retries a GET timeout and resolves on success', () async {
      adapter
        ..stage((options) => throw DioException(
              requestOptions: options,
              type: DioExceptionType.receiveTimeout,
            ))
        ..stage((options) => _ok(options));

      final res = await dio.get<dynamic>('/services');

      expect(res.statusCode, 200);
      expect(adapter.captureCount, 2);
    });

    test('does not retry a POST timeout', () async {
      adapter.stage(
        (options) => throw DioException(
          requestOptions: options,
          type: DioExceptionType.sendTimeout,
        ),
      );

      await expectLater(
        dio.post<dynamic>('/provider-services'),
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'type',
            DioExceptionType.sendTimeout,
          ),
        ),
      );
      expect(adapter.captureCount, 1);
    });

    test('does not retry a PATCH timeout', () async {
      adapter.stage(
        (options) => throw DioException(
          requestOptions: options,
          type: DioExceptionType.receiveTimeout,
        ),
      );

      await expectLater(
        dio.patch<dynamic>('/branches/1'),
        throwsA(isA<DioException>()),
      );
      expect(adapter.captureCount, 1);
    });

    test('still retries a PUT timeout (idempotent)', () async {
      adapter
        ..stage((options) => throw DioException(
              requestOptions: options,
              type: DioExceptionType.connectionTimeout,
            ))
        ..stage((options) => _ok(options));

      final res = await dio.put<dynamic>('/branches/1');

      expect(res.statusCode, 200);
      expect(adapter.captureCount, 2);
    });

    test('surfaces the error after exhausting retries for a GET', () async {
      adapter.stagePathHandler(
        (options) => throw DioException(
          requestOptions: options,
          type: DioExceptionType.receiveTimeout,
        ),
      );

      await expectLater(
        dio.get<dynamic>('/services'),
        throwsA(isA<DioException>()),
      );
      // Initial attempt + default maxRetries (2) = 3 total.
      expect(adapter.captureCount, 3);
    });
  });

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

// ─── Test doubles ─────────────────────────────────────────────────────────

typedef _Responder = ResponseBody Function(RequestOptions options);

class _StageableAdapter implements HttpClientAdapter {
  final List<_Responder> _staged = [];
  int captureCount = 0;
  _Responder? _pathHandler;

  void stage(_Responder r) => _staged.add(r);

  void stagePathHandler(_Responder r) => _pathHandler = r;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    captureCount++;
    if (_staged.isNotEmpty) return _staged.removeAt(0)(options);
    final ph = _pathHandler;
    if (ph != null) return ph(options);
    return _ok(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _ok(RequestOptions options) => ResponseBody.fromString(
  '{}',
  200,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);
