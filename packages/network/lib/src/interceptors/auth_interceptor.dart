import 'dart:async';
import 'dart:developer' as dev;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:network/src/token/token_manager.dart';

/// Production-grade auth interceptor.
///
/// 1. Injects `Authorization: Bearer <token>` on every outbound request.
/// 2. On 401, silently refreshes the token once and retries.
/// 3. Serialises concurrent 401s — only one refresh call is ever in-flight.
/// 4. Forces logout (via `onUnauthorized`) when refresh fails.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Dio dio,
    required TokenManager tokenManager,
    required String refreshTokenPath,
    void Function()? onUnauthorized,
  }) : _dio = dio,
       _tokenManager = tokenManager,
       _refreshTokenPath = refreshTokenPath,
       _onUnauthorized = onUnauthorized;

  final Dio _dio;
  final TokenManager _tokenManager;
  final String _refreshTokenPath;
  final void Function()? _onUnauthorized;

  bool _isRefreshing = false;
  final List<Completer<void>> _queue = [];
  static const _retriedKey = '_authRetried';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!options.headers.containsKey('Authorization')) {
      final token = _tokenManager.accessToken;
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      _log(
        'onRequest ${options.path} — token ${token == null
            ? "NULL"
            : token.isEmpty
            ? "EMPTY"
            : "present (${token.length} chars)"}',
      );
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;

    if (err.response?.statusCode != 401 ||
        options.path.contains(_refreshTokenPath)) {
      return handler.next(err);
    }
    if (options.extra[_retriedKey] == true) {
      return handler.next(err);
    }
    final stored = _tokenManager.refreshToken;
    if (stored == null || stored.isEmpty) {
      await _logout(handler, err);
      return;
    }

    if (_isRefreshing) {
      return _enqueue(options, handler, err);
    }

    _isRefreshing = true;
    _log('Refresh started');
    try {
      await _tokenManager.refreshAccessToken();
      _log('Refresh succeeded — resuming ${_queue.length} request(s)');
      _resolveQueue();
    } on TokenRefreshException catch (e) {
      _log('Refresh failed: ${e.message}');
      _rejectQueue(DioException(requestOptions: options, error: e));
      await _logout(handler, err);
      return;
    } on DioException catch (e) {
      _rejectQueue(e);
      await _logout(handler, err);
      return;
    } on Object catch (e) {
      _rejectQueue(DioException(requestOptions: options, error: e));
      await _logout(handler, err);
      return;
    } finally {
      _isRefreshing = false;
    }

    try {
      handler.resolve(await _retry(options));
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  Future<void> _enqueue(
    RequestOptions options,
    ErrorInterceptorHandler handler,
    DioException original,
  ) async {
    final c = Completer<void>();
    _queue.add(c);
    try {
      await c.future;
      handler.resolve(await _retry(options));
    } on DioException catch (e) {
      handler.next(e);
    } on Object catch (_) {
      handler.next(original);
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions options) {
    final token = _tokenManager.accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    options.extra[_retriedKey] = true;
    return _dio.fetch(options);
  }

  void _resolveQueue() {
    for (final c in _queue) {
      if (!c.isCompleted) c.complete();
    }
    _queue.clear();
  }

  void _rejectQueue(DioException err) {
    for (final c in _queue) {
      if (!c.isCompleted) c.completeError(err);
    }
    _queue.clear();
  }

  Future<void> _logout(
    ErrorInterceptorHandler handler,
    DioException original,
  ) async {
    try {
      await _tokenManager.clearTokens();
    } on Object catch (e) {
      _log('clearTokens threw during forced logout: $e');
    }
    _onUnauthorized?.call();
    handler.next(original);
  }

  void _log(String msg) {
    if (kDebugMode) dev.log('[AuthInterceptor] $msg', name: 'Network');
  }
}
