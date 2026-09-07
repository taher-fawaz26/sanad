import 'dart:async';

import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

enum RequestMethod { get, post, put, patch, delete }

/// Dio `options.extra` key carrying whether a request should be authenticated.
///
/// The default is `true` (attach the bearer token, handle 401-refresh). A
/// request that passes `authRequired: false` sets this to `false`, which the
/// `AuthInterceptor` reads to leave the request completely unauthenticated —
/// no `Authorization` header on the way out, no silent-refresh/logout on a
/// 401. Public endpoints (e.g. the pre-session OTP request/verify) use it so a
/// leftover token from a previous session is never attached to a call the
/// backend contract marks `Auth: None`.
const String kAuthRequiredExtraKey = 'authRequired';

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

    /// Whether to authenticate this request. Defaults to `true`. Pass `false`
    /// for endpoints the backend marks `Auth: None` (see
    /// [kAuthRequiredExtraKey]) so no bearer token is attached and a 401 does
    /// not trigger the refresh/logout machinery.
    bool authRequired = true,
  });
}
