import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network/src/interceptors/auth_interceptor.dart';
import 'package:network/src/token/token_manager.dart';

const _refreshPath = '/auth/refresh';

void main() {
  group('AuthInterceptor', () {
    late Dio dio;
    late _FakeTokenManager tokens;
    late _StageableAdapter adapter;
    var unauthorizedCallbacks = 0;

    setUp(() {
      dio = Dio();
      adapter = _StageableAdapter();
      dio.httpClientAdapter = adapter;
      tokens = _FakeTokenManager(access: 'a-1', refresh: 'r-1');
      unauthorizedCallbacks = 0;
      dio.interceptors.add(
        AuthInterceptor(
          dio: dio,
          tokenManager: tokens,
          refreshTokenPath: _refreshPath,
          onUnauthorized: () => unauthorizedCallbacks++,
        ),
      );
    });

    test('injects Bearer token on outbound requests', () async {
      adapter.stage((options) => _ok('{"ok":true}', options));
      final res = await dio.get<dynamic>('/workers');
      expect(res.statusCode, 200);
      expect(adapter.capturedAuthHeaders.single, 'Bearer a-1');
    });

    test('does not overwrite an existing Authorization header', () async {
      adapter.stage((options) => _ok('{"ok":true}', options));
      await dio.get<dynamic>(
        '/workers',
        options: Options(headers: {'Authorization': 'Bearer preset'}),
      );
      expect(adapter.capturedAuthHeaders.single, 'Bearer preset');
    });

    test('on 401 refreshes once and retries with the new token', () async {
      tokens.refreshImpl = () async {
        tokens.access = 'a-2';
        return 'a-2';
      };
      adapter
        ..stage((options) => _status(401, options))
        ..stage((options) => _ok('{"ok":true}', options));

      final res = await dio.get<dynamic>('/workers');

      expect(res.statusCode, 200);
      expect(tokens.refreshCalls, 1);
      expect(adapter.capturedAuthHeaders.length, 2);
      expect(adapter.capturedAuthHeaders[0], 'Bearer a-1');
      expect(adapter.capturedAuthHeaders[1], 'Bearer a-2');
      expect(adapter.capturedRetryFlags[1], isTrue);
    });

    test('concurrent 401s share a single refresh (single-flight)', () async {
      // Gate the refresh so we can inspect state while it's in-flight.
      final refreshGate = Completer<String>();
      tokens.refreshImpl = () async {
        final t = await refreshGate.future;
        tokens.access = t;
        return t;
      };

      // Adapter: on-path yields 401 on first attempt, 200 on retry.
      // Also yield with a microtask delay per response so all 4 fetches
      // complete in interleaved order rather than a single batch.
      adapter.stagePathHandler((options) {
        if (options.extra['_authRetried'] == true) {
          return _ok('{"ok":true}', options);
        }
        return _status(401, options);
      });

      final futures = [
        for (var i = 0; i < 4; i++) dio.get<dynamic>('/workers'),
      ];

      // Drain microtasks until refresh is in-flight and 3 requests are queued.
      // The exact number of pumps needed depends on Dio's internals; loop until
      // we observe the interceptor's single-flight state.
      for (var i = 0; i < 20 && tokens.refreshCalls < 1; i++) {
        await Future<void>.delayed(Duration.zero);
      }

      expect(
        tokens.refreshCalls,
        1,
        reason: 'exactly one refresh should be in-flight while others queue',
      );

      refreshGate.complete('a-2');
      final results = await Future.wait(futures);

      for (final r in results) {
        expect(r.statusCode, 200);
      }
      expect(
        tokens.refreshCalls,
        1,
        reason: 'refreshAccessToken must remain single-flight',
      );
      // 4 initial 401s + 4 retries = 8 total captures.
      expect(adapter.captureCount, 8);
    });

    test('401 on the refresh endpoint itself is not retried', () async {
      adapter.stage((options) => _status(401, options));

      await expectLater(
        dio.get<dynamic>(_refreshPath),
        throwsA(isA<DioException>()),
      );
      expect(tokens.refreshCalls, 0);
    });

    test('_retriedKey guard prevents a second refresh on the same request',
        () async {
      tokens.refreshImpl = () async => 'a-2';
      adapter.stagePathHandler((_) => _statusOnly(401));

      // Two 401s in a row: first triggers refresh + retry; retry still 401 →
      // interceptor must NOT refresh again because _authRetried is set.
      await expectLater(
        dio.get<dynamic>('/workers'),
        throwsA(isA<DioException>()),
      );
      expect(tokens.refreshCalls, 1);
    });

    test('refresh failure clears tokens and fires onUnauthorized', () async {
      tokens.refreshImpl =
          () async => throw const TokenRefreshException('boom');
      adapter.stage((options) => _status(401, options));

      await expectLater(
        dio.get<dynamic>('/workers'),
        throwsA(isA<DioException>()),
      );

      expect(tokens.clearCalls, 1);
      expect(unauthorizedCallbacks, 1);
    });

    test('missing refresh token triggers immediate logout on 401', () async {
      tokens.refresh = null;
      adapter.stage((options) => _status(401, options));

      await expectLater(
        dio.get<dynamic>('/workers'),
        throwsA(isA<DioException>()),
      );

      expect(tokens.refreshCalls, 0);
      expect(tokens.clearCalls, 1);
      expect(unauthorizedCallbacks, 1);
    });
  });
}

// ─── Test doubles ─────────────────────────────────────────────────────────

class _FakeTokenManager implements TokenManager {
  _FakeTokenManager({this.access, this.refresh});

  String? access;
  String? refresh;
  int refreshCalls = 0;
  int clearCalls = 0;
  Future<String> Function()? refreshImpl;

  @override
  String? get accessToken => access;

  @override
  String? get refreshToken => refresh;

  @override
  Future<void> init() async {}

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    access = accessToken;
    refresh = refreshToken;
  }

  @override
  Future<void> clearTokens() async {
    clearCalls++;
    access = null;
    refresh = null;
  }

  @override
  Future<String> refreshAccessToken() async {
    refreshCalls++;
    final impl = refreshImpl;
    if (impl == null) {
      throw const TokenRefreshException('no impl configured');
    }
    return impl();
  }
}

typedef _Responder = ResponseBody Function(RequestOptions options);

class _StageableAdapter implements HttpClientAdapter {
  final List<_Responder> _staged = [];
  final List<String?> capturedAuthHeaders = [];
  final List<bool?> capturedRetryFlags = [];
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
    capturedAuthHeaders.add(options.headers['Authorization']?.toString());
    capturedRetryFlags.add(options.extra['_authRetried'] as bool?);
    if (_staged.isNotEmpty) return _staged.removeAt(0)(options);
    final ph = _pathHandler;
    if (ph != null) return ph(options);
    return _ok('{}', options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _ok(String body, RequestOptions options) =>
    ResponseBody.fromString(
      body,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

ResponseBody _status(int code, RequestOptions options) =>
    ResponseBody.fromString(
      '{}',
      code,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

ResponseBody _statusOnly(int code) => ResponseBody.fromString(
  '{}',
  code,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);
