import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network/src/interceptors/accept_language_interceptor.dart';

void main() {
  group('AcceptLanguageInterceptor', () {
    late _CapturingAdapter adapter;

    Dio buildDio(String Function() resolveLanguageCode) {
      final dio = Dio();
      adapter = _CapturingAdapter();
      dio.httpClientAdapter = adapter;
      dio.interceptors.add(
        AcceptLanguageInterceptor(resolveLanguageCode: resolveLanguageCode),
      );
      return dio;
    }

    test('sets Accept-Language and x-lang for an Arabic locale', () async {
      final dio = buildDio(() => 'ar');

      await dio.get<dynamic>('/services');

      final options = adapter.lastOptions!;
      expect(options.headers['Accept-Language'], 'ar');
      expect(options.headers['x-lang'], 'ar');
    });

    test('sets Accept-Language and x-lang for an English locale', () async {
      final dio = buildDio(() => 'en');

      await dio.get<dynamic>('/services');

      final options = adapter.lastOptions!;
      expect(options.headers['Accept-Language'], 'en');
      expect(options.headers['x-lang'], 'en');
    });

    test('defaults to "en" for an unrecognized language code', () async {
      // English is the product default (SAN-774); this used to fall back to
      // Arabic, so an unresolvable code silently served Arabic content.
      final dio = buildDio(() => 'fr');

      await dio.get<dynamic>('/services');

      final options = adapter.lastOptions!;
      expect(options.headers['Accept-Language'], 'en');
      expect(options.headers['x-lang'], 'en');
    });

    test('defaults to "en" for an empty language code', () async {
      final dio = buildDio(() => '');

      await dio.get<dynamic>('/services');

      expect(adapter.lastOptions!.headers['x-lang'], 'en');
    });

    test('normalizes a full locale tag down to its primary subtag', () async {
      // The backend only accepts a bare `ar`/`en` on `x-lang` and silently
      // defaults to English for anything else, so `ar-AR` / `ar_AR` (Dart's
      // own `Locale.toString()` form) must not reach it verbatim.
      for (final entry in {
        'ar-AR': 'ar',
        'ar_AR': 'ar',
        'AR': 'ar',
        'en-US': 'en',
        'en_US': 'en',
      }.entries) {
        final dio = buildDio(() => entry.key);

        await dio.get<dynamic>('/services');

        final options = adapter.lastOptions!;
        expect(
          options.headers['Accept-Language'],
          entry.value,
          reason: entry.key,
        );
        expect(options.headers['x-lang'], entry.value, reason: entry.key);
      }
    });

    test(
      'never adds a lang query parameter — regression guard. A prior fix '
      'attempt did this globally to work around SAN-579 (catalog service '
      'names showing English under an Arabic UI) and it broke '
      'provider-services/service-requests with a 400 (property lang should '
      'not exist); the verified Services Module API contract documents each '
      "endpoint's allowed query params explicitly and lang is not one of "
      'them anywhere — localization is header-only (x-lang/Accept-Language)',
      () async {
        final dio = buildDio(() => 'ar');

        await dio.get<dynamic>(
          '/provider-services',
          queryParameters: {'page': 1, 'limit': 10},
        );

        final options = adapter.lastOptions!;
        expect(options.queryParameters.containsKey('lang'), isFalse);
        // Existing query params must still pass through untouched.
        expect(options.queryParameters['page'], 1);
        expect(options.queryParameters['limit'], 10);
      },
    );
  });
}

// ─── Test doubles ─────────────────────────────────────────────────────────

class _CapturingAdapter implements HttpClientAdapter {
  RequestOptions? lastOptions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastOptions = options;
    return ResponseBody.fromString(
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
