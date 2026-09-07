import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';
import 'package:testing/testing.dart';
import 'package:text_optimization/src/data/datasources/text_optimization_remote_datasource.dart';

void main() {
  group('TextOptimizationRemoteDataSourceImpl', () {
    test(
      'POSTs {"text": ...} — and only that — to the enhance-text path',
      () async {
        String? sentPath;
        RequestMethod? sentMethod;
        dynamic sentBody;
        final client = _CapturingApiClient(
          onRequest: (path, method, body) {
            sentPath = path;
            sentMethod = method;
            sentBody = body;
          },
          response: TaskEither.right({'enhanced_text': 'enhanced'}),
        );
        final dataSource = TextOptimizationRemoteDataSourceImpl(client);

        await dataSource.optimize('raw text').run();

        expect(sentPath, TextOptimizationApiConfig.enhanceTextPath);
        // Base-URL-relative (no leading slash, no `/api/v1`). `baseUrl` already
        // ends in `/api/v1/`; a leading `/api/v1` here doubled the prefix and
        // 404'd. See the composed-URL regression test in
        // packages/network/test/src/config/text_optimization_api_config_test.dart.
        expect(sentPath, 'agent/enhance-text');
        expect(sentMethod, RequestMethod.post);
        // Exactly one property — no `model` or any other field.
        expect(sentBody, {'text': 'raw text'});
      },
    );

    test('reads `enhanced_text` from the response, trimmed', () async {
      final client = FakeBaseApiClient(
        responses: {
          TextOptimizationApiConfig.enhanceTextPath: TaskEither.right({
            'enhanced_text': '  We fix ACs and do plumbing.  ',
          }),
        },
      );
      final dataSource = TextOptimizationRemoteDataSourceImpl(client);

      final result = await dataSource.optimize('x').run();

      expect(
        result,
        const Right<Failure, String>('We fix ACs and do plumbing.'),
      );
    });

    test('ignores extra/future response fields', () async {
      final client = FakeBaseApiClient(
        responses: {
          TextOptimizationApiConfig.enhanceTextPath: TaskEither.right({
            'enhanced_text': 'Improved text',
            'model': 'whatever',
            'requestId': 'abc-123',
          }),
        },
      );
      final dataSource = TextOptimizationRemoteDataSourceImpl(client);

      final result = await dataSource.optimize('x').run();

      expect(result, const Right<Failure, String>('Improved text'));
    });

    test(
      'a response missing `enhanced_text` maps to a failure',
      () async {
        // FakeBaseApiClient doesn't replicate ApiClientImpl's tryCatch around
        // the parser call, so this double does — the real client catches a
        // parser exception and maps it to a Failure rather than letting it
        // escape uncaught.
        final client = _ParserExceptionAwareApiClient(
          data: {'text': 'wrong key'},
        );
        final dataSource = TextOptimizationRemoteDataSourceImpl(client);

        final result = await dataSource.optimize('x').run();

        expect(result.isLeft(), isTrue);
      },
    );

    test('a bare-string response maps to a failure', () async {
      final client = _ParserExceptionAwareApiClient(data: 'plain string');
      final dataSource = TextOptimizationRemoteDataSourceImpl(client);

      final result = await dataSource.optimize('x').run();

      expect(result.isLeft(), isTrue);
    });

    test('propagates a client-mapped failure unchanged', () async {
      const failure = ValidationFailure(
        message: 'text must be longer than or equal to 5 characters',
        code: '400',
      );
      final client = FakeBaseApiClient(
        responses: {
          TextOptimizationApiConfig.enhanceTextPath: TaskEither.left(failure),
        },
      );
      final dataSource = TextOptimizationRemoteDataSourceImpl(client);

      final result = await dataSource.optimize('x').run();

      expect(result, const Left<Failure, String>(failure));
    });
  });
}

/// Captures the exact `request` call arguments a real `BaseApiClient` would
/// receive, then hands the configured [response] through the parser — used
/// to assert the outgoing request shape independently of response parsing.
class _CapturingApiClient implements BaseApiClient {
  _CapturingApiClient({required this.onRequest, required this.response});

  final void Function(String path, RequestMethod method, dynamic body)
  onRequest;
  final TaskEither<Failure, dynamic> response;

  @override
  TaskEither<Failure, T> request<T>({
    required String path,
    required RequestMethod method,
    required FutureOr<T> Function(dynamic data) parser,
    Map<String, dynamic>? query,
    dynamic body,
    bool authRequired = true,
  }) {
    onRequest(path, method, body);
    return TaskEither(() async {
      final result = await response.run();
      return result.match(left, (data) async => right(await parser(data)));
    });
  }
}

/// Mirrors `ApiClientImpl.request`'s `TaskEither.tryCatch` around the parser
/// call — a thrown parser exception becomes a `Left`, not an uncaught error.
class _ParserExceptionAwareApiClient implements BaseApiClient {
  _ParserExceptionAwareApiClient({required this.data});

  final dynamic data;

  @override
  TaskEither<Failure, T> request<T>({
    required String path,
    required RequestMethod method,
    required FutureOr<T> Function(dynamic data) parser,
    Map<String, dynamic>? query,
    dynamic body,
    bool authRequired = true,
  }) => TaskEither<Failure, T>.tryCatch(
    () async => parser(data),
    (error, _) =>
        const UnknownFailure(message: 'unexpected', code: 'unexpected_format'),
  );
}
