import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';

/// In-memory [BaseApiClient] for data-source unit tests.
class FakeBaseApiClient implements BaseApiClient {
  FakeBaseApiClient({this.responses = const {}});

  /// Map of `path` → configured response.
  final Map<String, TaskEither<Failure, dynamic>> responses;

  /// Default response when no path-specific handler is registered.
  TaskEither<Failure, dynamic> defaultResponse =
      TaskEither.left(const NetworkFailure(message: 'not configured'));

  @override
  TaskEither<Failure, T> request<T>({
    required String path,
    required RequestMethod method,
    required T Function(dynamic data) parser,
    Map<String, dynamic>? query,
    dynamic body,
  }) {
    final handler = responses[path] ?? defaultResponse;
    return handler.map((data) => parser(data));
  }
}
