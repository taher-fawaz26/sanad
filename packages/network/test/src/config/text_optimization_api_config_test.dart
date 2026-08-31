import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network/src/config/text_optimization_api_config.dart';

void main() {
  group('TextOptimizationApiConfig.enhanceTextPath composition', () {
    late _CapturingAdapter adapter;

    // Mirrors the real app: `AppConfig.network.baseUrl` already ends in
    // `/api/v1/` (e.g. `https://dev-api.trysanad.us/api/v1/`). Dio composes the
    // request URL as `baseUrl + path`, so the endpoint constant must be
    // base-URL-relative.
    Dio buildDio(String baseUrl) {
      final dio = Dio(BaseOptions(baseUrl: baseUrl));
      adapter = _CapturingAdapter();
      dio.httpClientAdapter = adapter;
      return dio;
    }

    test(
      'the endpoint constant is base-URL-relative — no leading slash, no '
      '`/api/v1` prefix — so it never bypasses/duplicates the configured base',
      () {
        expect(TextOptimizationApiConfig.enhanceTextPath, 'agent/enhance-text');
        expect(
          TextOptimizationApiConfig.enhanceTextPath.startsWith('/'),
          isFalse,
        );
        expect(
          TextOptimizationApiConfig.enhanceTextPath.startsWith('http'),
          isFalse,
        );
      },
    );

    test(
      'composes to exactly /api/v1/agent/enhance-text against the dev base URL '
      '— regression for the double-prefix 404 '
      '(POST /api/v1/api/v1/agent/enhance-text)',
      () async {
        final dio = buildDio('https://dev-api.trysanad.us/api/v1/');

        await dio.post<dynamic>(
          TextOptimizationApiConfig.enhanceTextPath,
          data: {'text': 'raw text'},
        );

        final uri = adapter.lastOptions!.uri;
        expect(uri.path, '/api/v1/agent/enhance-text');
        expect(
          uri.toString(),
          'https://dev-api.trysanad.us/api/v1/agent/enhance-text',
        );
        // Explicitly guard against the two failure modes we saw / could see:
        expect(uri.path, isNot(contains('/api/v1/api/v1/')));
        expect(uri.path, isNot('/agent/enhance-text'));
      },
    );

    test('composes correctly against the production base URL too', () async {
      final dio = buildDio('https://api.trysanad.us/api/v1/');

      await dio.post<dynamic>(
        TextOptimizationApiConfig.enhanceTextPath,
        data: {'text': 'raw text'},
      );

      expect(
        adapter.lastOptions!.uri.toString(),
        'https://api.trysanad.us/api/v1/agent/enhance-text',
      );
    });
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
      '{"enhanced_text": "enhanced"}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
