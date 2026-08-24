import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';
import 'package:testing/testing.dart';
import 'package:text_optimization/src/data/datasources/text_optimization_remote_datasource.dart';

void main() {
  group('TextOptimizationRemoteDataSourceImpl', () {
    test('sends the text as {"text": ...} to the configured path', () async {
      String? sentPath;
      RequestMethod? sentMethod;
      dynamic sentBody;
      final client = _CapturingApiClient(
        onRequest: (path, method, body) {
          sentPath = path;
          sentMethod = method;
          sentBody = body;
        },
        response: TaskEither.right('optimized'),
      );
      final dataSource = TextOptimizationRemoteDataSourceImpl(client);

      await dataSource.optimize('raw text').run();

      expect(sentPath, TextOptimizationApiConfig.optimizePath);
      expect(sentMethod, RequestMethod.post);
      expect(sentBody, {'text': 'raw text'});
    });

    test('a bare-string response is returned trimmed', () async {
      final client = FakeBaseApiClient(
        responses: {
          TextOptimizationApiConfig.optimizePath: TaskEither.right(
            '  Optimized text.  ',
          ),
        },
      );
      final dataSource = TextOptimizationRemoteDataSourceImpl(client);

      final result = await dataSource.optimize('x').run();

      expect(result, const Right<Failure, String>('Optimized text.'));
    });

    test(
      'a {"text": ...} response shape is accepted defensively even though '
      "the contract doesn't promise it",
      () async {
        final client = FakeBaseApiClient(
          responses: {
            TextOptimizationApiConfig.optimizePath: TaskEither.right({
              'text': 'Optimized text.',
            }),
          },
        );
        final dataSource = TextOptimizationRemoteDataSourceImpl(client);

        final result = await dataSource.optimize('x').run();

        expect(result, const Right<Failure, String>('Optimized text.'));
      },
    );

    test('an empty string response is returned as an empty string', () async {
      final client = FakeBaseApiClient(
        responses: {
          TextOptimizationApiConfig.optimizePath: TaskEither.right(''),
        },
      );
      final dataSource = TextOptimizationRemoteDataSourceImpl(client);

      final result = await dataSource.optimize('x').run();

      expect(result, const Right<Failure, String>(''));
    });

    test(
      'an unexpected response shape (e.g. a bare number) maps to a failure',
      () async {
        // FakeBaseApiClient doesn't replicate ApiClientImpl's tryCatch
        // around the parser call, so this double does — the real client
        // catches a parser exception and maps it to a Failure rather than
        // letting it escape uncaught.
        final client = _ParserExceptionAwareApiClient(data: 42);
        final dataSource = TextOptimizationRemoteDataSourceImpl(client);

        final result = await dataSource.optimize('x').run();

        expect(result.isLeft(), isTrue);
      },
    );

    test('propagates a client-mapped failure unchanged', () async {
      const failure = TimeoutFailure(message: 'errors.timeout');
      final client = FakeBaseApiClient(
        responses: {
          TextOptimizationApiConfig.optimizePath: TaskEither.left(failure),
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
  }) => TaskEither<Failure, T>.tryCatch(
    () async => parser(data),
    (error, _) =>
        const UnknownFailure(message: 'unexpected', code: 'unexpected_format'),
  );
}
