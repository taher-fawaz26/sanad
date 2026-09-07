import 'dart:async';
import 'dart:convert';

import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/ai_ui_renderer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network/network.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/websocket_ai_chat_event_source.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// A socket the test drives directly: [serverSend] pushes a frame at the
/// client, [sent] records what the client wrote.
class _FakeChannel extends StreamChannelMixin<dynamic>
    implements WebSocketChannel {
  _FakeChannel({this.readyError});

  final Object? readyError;

  final StreamController<dynamic> _incoming = StreamController<dynamic>();
  final List<String> sent = <String>[];
  final _FakeSink _sink = _FakeSink();

  bool get isClosed => _sink.closed;
  int? get sentCloseCode => _sink.closeCode;

  void serverSend(String frame) => _incoming.add(frame);

  Future<void> serverClose() => _incoming.close();

  @override
  Stream<dynamic> get stream => _incoming.stream;

  @override
  WebSocketSink get sink {
    _sink.channel = this;
    return _sink;
  }

  @override
  Future<void> get ready => readyError == null
      ? Future<void>.value()
      : Future<void>.error(readyError!);

  @override
  String? get protocol => null;

  @override
  int? get closeCode => _sink.closeCode;

  @override
  String? get closeReason => null;
}

class _FakeSink implements WebSocketSink {
  _FakeChannel? channel;
  bool closed = false;
  int? closeCode;

  @override
  void add(dynamic data) => channel!.sent.add(data as String);

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    closed = true;
    this.closeCode = closeCode;
    await channel?._incoming.close();
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<dynamic> stream) async {}

  @override
  Future<void> get done => Future<void>.value();
}

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

class _RecordingSink extends AiUiDiagnosticsSink {
  final List<AiUiDiagnostic> reported = <AiUiDiagnostic>[];

  @override
  void report(AiUiDiagnostic diagnostic) => reported.add(diagnostic);
}

const _token = 'test-access-token-value';

String _frame(String type, Map<String, dynamic> payload, {int seq = 0}) =>
    jsonEncode(<String, dynamic>{
      'eventId': 'evt_$seq',
      'conversationId': 'conv_1',
      'messageId': 'msg_1',
      'seq': seq,
      'type': type,
      'createdAt': '2026-09-02T11:09:17.065436Z',
      'payload': payload,
    });

void main() {
  late _FakeChannel channel;
  late _RecordingSink diagnostics;
  late List<Map<String, String>> capturedHeaders;

  WebSocketAiChatEventSource build({String? token = _token}) {
    capturedHeaders = <Map<String, String>>[];
    return WebSocketAiChatEventSource(
      url: Uri.parse('wss://agent-dev.example/agent/chat/ws'),
      tokenManager: _FakeTokenManager(token),
      conversationId: 'conv_1',
      diagnostics: diagnostics,
      connector: (url, headers) {
        capturedHeaders.add(headers);
        return channel;
      },
    );
  }

  setUp(() {
    channel = _FakeChannel();
    diagnostics = _RecordingSink();
  });

  group('authentication', () {
    test('attaches the existing access token as a handshake header', () async {
      final source = build();
      await source.send('hi');

      expect(capturedHeaders, hasLength(1));
      expect(capturedHeaders.single[kSanadAccessTokenHeader], _token);

      await source.dispose();
    });

    test('never puts the token in the message body', () async {
      final source = build();
      await source.send('hi');

      final body = jsonDecode(channel.sent.single) as Map<String, dynamic>;
      expect(
        body.keys,
        unorderedEquals(<String>['conversation_id', 'message']),
      );
      expect(channel.sent.single, isNot(contains(_token)));

      await source.dispose();
    });

    test('connects without the header when there is no session', () async {
      final source = build(token: null);
      await source.send('hi');

      expect(capturedHeaders.single, isEmpty);

      await source.dispose();
    });
  });

  group('sending', () {
    test('sends conversation_id and message', () async {
      final source = build();
      await source.send('find me a service');

      expect(
        jsonDecode(channel.sent.single),
        <String, dynamic>{
          'conversation_id': 'conv_1',
          'message': 'find me a service',
        },
      );

      await source.dispose();
    });

    test('reuses one socket across turns', () async {
      final source = build();
      await source.send('one');
      await source.send('two');

      expect(capturedHeaders, hasLength(1));
      expect(channel.sent, hasLength(2));

      await source.dispose();
    });

    test('concurrent sends do not open two sockets', () async {
      final source = build();
      await Future.wait<void>([source.send('one'), source.send('two')]);

      expect(capturedHeaders, hasLength(1));

      await source.dispose();
    });
  });

  group('receiving', () {
    test('decodes frames in order, including ui after message_end', () async {
      final source = build();
      final received = <AiChatEvent>[];
      final sub = source.events.listen(received.add);

      await source.send('hi');
      channel
        ..serverSend(_frame('message_start', {'role': 'assistant'}))
        ..serverSend(_frame('text_delta', {'delta': 'Hello'}, seq: 1))
        ..serverSend(_frame('message_end', {'text': 'Hello'}, seq: 2))
        ..serverSend(
          _frame('ui', {
            'schemaVersion': 1,
            'blocks': [
              {
                'type': 'button',
                'id': 'image_upload',
                'label': 'Upload photos',
                'action': {'type': 'request_image_upload'},
              },
            ],
          }, seq: 3),
        );
      await pumpEventQueue();

      expect(
        received.map((e) => e.type).toList(),
        <AiChatEventType>[
          AiChatEventType.messageStart,
          AiChatEventType.textDelta,
          AiChatEventType.messageEnd,
          AiChatEventType.ui,
        ],
      );
      expect(received.map((e) => e.seq).toList(), <int>[0, 1, 2, 3]);

      await sub.cancel();
      await source.dispose();
    });

    test('drops a malformed frame with a diagnostic and keeps going', () async {
      final source = build();
      final received = <AiChatEvent>[];
      final sub = source.events.listen(received.add);

      await source.send('hi');
      channel
        ..serverSend('{not json')
        ..serverSend(_frame('typing', {'active': true}, seq: 1));
      await pumpEventQueue();

      expect(diagnostics.reported, isNotEmpty);
      expect(received.single.type, AiChatEventType.typing);

      await sub.cancel();
      await source.dispose();
    });

    test('surfaces an agent error frame verbatim', () async {
      final source = build();
      final received = <AiChatEvent>[];
      final sub = source.events.listen(received.add);

      await source.send('hi');
      channel.serverSend(
        _frame('error', {
          'code': 'invalid_request',
          'message': 'field required',
        }),
      );
      await pumpEventQueue();

      expect(
        received.single,
        isA<AiChatErrorEvent>()
            .having((e) => e.code, 'code', 'invalid_request')
            .having((e) => e.message, 'message', 'field required'),
      );

      await sub.cancel();
      await source.dispose();
    });
  });

  group('failure handling', () {
    test('a dropped socket becomes a local error event', () async {
      final source = build();
      final received = <AiChatEvent>[];
      final sub = source.events.listen(received.add);

      await source.send('hi');
      // Live behaviour: the server kills the socket with no error frame.
      await channel.serverClose();
      await pumpEventQueue();

      expect(
        received.single,
        isA<AiChatErrorEvent>().having(
          (e) => e.code,
          'code',
          'connection_closed',
        ),
      );

      await sub.cancel();
      await source.dispose();
    });

    test('reconnects on the next send after a drop', () async {
      final source = build();
      await source.send('one');
      await channel.serverClose();
      await pumpEventQueue();

      channel = _FakeChannel();
      await source.send('two');

      expect(capturedHeaders, hasLength(2));
      expect(channel.sent.single, contains('two'));

      await source.dispose();
    });

    test('a failed handshake reports an error without throwing', () async {
      channel = _FakeChannel(readyError: StateError('no route to host'));
      final source = build();
      final received = <AiChatEvent>[];
      final sub = source.events.listen(received.add);

      await source.send('hi');
      await pumpEventQueue();

      expect(
        received.single,
        isA<AiChatErrorEvent>().having(
          (e) => e.code,
          'code',
          'connection_failed',
        ),
      );
      expect(channel.sent, isEmpty);

      await sub.cancel();
      await source.dispose();
    });

    test('no diagnostic or error text ever contains the token', () async {
      channel = _FakeChannel(readyError: StateError('boom'));
      final source = build();
      final received = <AiChatEvent>[];
      final sub = source.events.listen(received.add);

      await source.send('hi');
      await pumpEventQueue();

      for (final diagnostic in diagnostics.reported) {
        expect(diagnostic.toString(), isNot(contains(_token)));
      }
      for (final event in received) {
        expect(jsonEncode(event.toJson()), isNot(contains(_token)));
      }

      await sub.cancel();
      await source.dispose();
    });
  });

  group('disposal', () {
    test('closes the socket with a normal close code', () async {
      final source = build();
      await source.send('hi');
      await source.dispose();

      expect(channel.isClosed, isTrue);
      expect(channel.sentCloseCode, 1000);
    });

    test('is idempotent and emits no error for its own close', () async {
      final source = build();
      final received = <AiChatEvent>[];
      final sub = source.events.listen(received.add);

      await source.send('hi');
      await source.dispose();
      await source.dispose();
      await pumpEventQueue();

      expect(received, isEmpty);

      await sub.cancel();
    });

    test('send after dispose is a no-op', () async {
      final source = build();
      await source.dispose();
      await source.send('hi');

      expect(capturedHeaders, isEmpty);
    });
  });
}
