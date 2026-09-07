@TestOn('vm')
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:network/network.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/websocket_ai_chat_event_source.dart';

/// A `_FakeChannel` proves the source *asks* for the header. This proves the
/// production connector actually puts it on the wire: it runs a real HTTP
/// server, performs a real WebSocket upgrade, and reads the handshake request.
///
/// Without this, `connector:` could be attaching headers that
/// `IOWebSocketChannel.connect` silently ignores and every unit test would
/// still pass.
class _FakeTokenManager implements TokenManager {
  _FakeTokenManager(this._token);

  final String? _token;

  @override
  String? get accessToken => _token;

  @override
  String? get refreshToken => null;

  @override
  Future<void> init() async {}

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {}

  @override
  Future<void> clearTokens() async {}

  @override
  Future<String> refreshAccessToken() async => '';
}

void main() {
  late HttpServer server;
  late Completer<HttpHeaders> handshake;

  setUp(() async {
    handshake = Completer<HttpHeaders>();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    unawaited(
      server.first.then((request) async {
        if (!handshake.isCompleted) handshake.complete(request.headers);
        final socket = await WebSocketTransformer.upgrade(request);
        await socket.close();
      }),
    );
  });

  tearDown(() => server.close(force: true));

  test('the production connector sends the token in the handshake', () async {
    const token = 'handshake-probe-token';
    final source = WebSocketAiChatEventSource(
      url: Uri.parse('ws://${server.address.address}:${server.port}/ws'),
      tokenManager: _FakeTokenManager(token),
      conversationId: 'conv_handshake',
    );

    await source.send('hello');
    final headers = await handshake.future.timeout(
      const Duration(seconds: 10),
    );

    expect(headers.value(kSanadAccessTokenHeader), token);

    await source.dispose();
  });

  test('no session means no header, and the connection still opens', () async {
    final source = WebSocketAiChatEventSource(
      url: Uri.parse('ws://${server.address.address}:${server.port}/ws'),
      tokenManager: _FakeTokenManager(null),
      conversationId: 'conv_handshake',
    );

    await source.send('hello');
    final headers = await handshake.future.timeout(
      const Duration(seconds: 10),
    );

    expect(headers.value(kSanadAccessTokenHeader), isNull);

    await source.dispose();
  });
}
