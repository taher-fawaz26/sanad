import 'dart:async';

import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

enum RequestMethod { get, post, put, patch, delete }

/// High-level API client. All requests return [TaskEither] for consistent
/// functional chaining. No [Future<Either>] anywhere.
///
/// [parser] returns `FutureOr<T>` so callers can opt into off-main-thread
/// parsing via `parseListInIsolate` / `parseInIsolate` for large responses
/// — the client `await`s whatever the parser yields.
// ignore: one_member_abstracts
abstract class BaseApiClient {
  TaskEither<Failure, T> request<T>({
    required String path,
    required RequestMethod method,
    required FutureOr<T> Function(dynamic data) parser,
    Map<String, dynamic>? query,
    dynamic body,
  });
}
