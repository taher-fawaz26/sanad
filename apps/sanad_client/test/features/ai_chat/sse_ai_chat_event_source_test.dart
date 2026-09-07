import 'dart:async';
import 'dart:convert';

import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/ai_ui_renderer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network/network.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/sse_ai_chat_event_source.dart';

/// A token that must never appear anywhere but the request header.
const String kProbeToken = 'tok_SECRET_c0ffee_do_not_leak';

const String kConversationId = 'conv_test_1';
final Uri kUrl = Uri.parse('https://agent-dev.example/user-agent/chat/stream');

// ─── fakes ──────────────────────────────────────────────────────────────────

class _FakeTokenManager implements TokenManager {
  _FakeTokenManager({this.token});

  String? token;

  @override
  String? get accessToken => token;

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
  Future<String> refreshAccessToken() async =>
      throw UnimplementedError('not exercised by the transport');
}

/// Stands in for the HTTP client. Records what was asked for and hands back a
/// body the test drives byte by byte.
class _FakeConnector {
  final List<AiChatSseRequest> requests = <AiChatSseRequest>[];
  final List<StreamController<List<int>>> bodies =
      <StreamController<List<int>>>[];

  int status = 200;

  /// Thrown from the open, to simulate a connect failure or a connect timeout.
  Exception? throwOnOpen;

  /// Held to keep the open pending, so a test can cancel mid-connect.
  Completer<void>? gate;

  Future<AiChatSseResponse> call(AiChatSseRequest request) async {
    requests.add(request);
    if (gate != null) await gate!.future;
    final error = throwOnOpen;
    if (error != null) throw error;
    final body = StreamController<List<int>>();
    bodies.add(body);
    return AiChatSseResponse(statusCode: status, body: body.stream);
  }

  AiChatSseRequest get request => requests.last;
  StreamController<List<int>> get body => bodies.last;
}

class _RecordingSink extends AiUiDiagnosticsSink {
  final List<AiUiDiagnostic> diagnostics = <AiUiDiagnostic>[];

  @override
  void report(AiUiDiagnostic diagnostic) => diagnostics.add(diagnostic);

  String get text => diagnostics
      .map((d) => '${d.code.wire}|${d.path}|${d.nodeType}|${d.detail}')
      .join('\n');
}

// ─── wire helpers ───────────────────────────────────────────────────────────

String frame(Object? payload) => 'data: ${jsonEncode(payload)}\n\n';

Map<String, dynamic> envelope({
  required String type,
  required String eventId,
  int seq = 0,
  String? messageId = 'msg_1',
  Map<String, dynamic> payload = const <String, dynamic>{},
}) => <String, dynamic>{
  'eventId': eventId,
  'conversationId': kConversationId,
  if (messageId != null) 'messageId': messageId,
  'seq': seq,
  'type': type,
  'createdAt': '2026-09-04T20:56:51.354837Z',
  'payload': payload,
};

String startFrame() => frame(
  envelope(
    type: 'message_start',
    eventId: 'evt_0',
    payload: const {'role': 'assistant'},
  ),
);

String deltaFrame(String delta, int seq) => frame(
  envelope(
    type: 'text_delta',
    eventId: 'evt_$seq',
    seq: seq,
    payload: {
      'delta': delta,
    },
  ),
);

String endFrame(String text, int seq) => frame(
  envelope(
    type: 'message_end',
    eventId: 'evt_$seq',
    seq: seq,
    payload: {
      'text': text,
    },
  ),
);

// ─── harness ────────────────────────────────────────────────────────────────

class _Harness {
  _Harness({String? token})
    : connector = _FakeConnector(),
      diagnostics = _RecordingSink(),
      tokens = _FakeTokenManager(token: token) {
    source = SseAiChatEventSource(
      url: kUrl,
      tokenManager: tokens,
      conversationId: kConversationId,
      diagnostics: diagnostics,
      connector: connector.call,
    );
    subscription = source.events.listen(events.add);
  }

  final _FakeConnector connector;
  final _RecordingSink diagnostics;
  final _FakeTokenManager tokens;
  late final SseAiChatEventSource source;
  late final StreamSubscription<AiChatEvent> subscription;
  final List<AiChatEvent> events = <AiChatEvent>[];

  /// Sends a turn and lets any resulting event reach the listener.
  ///
  /// `_controller` is a broadcast controller, so it delivers asynchronously —
  /// without the pump an error emitted during `send` would not have arrived by
  /// the time the assertion runs.
  Future<void> send(String text) async {
    await source.send(text);
    await pumpEventQueue();
  }

  /// Pushes [text] into the open body as UTF-8 bytes and lets it be delivered.
  Future<void> emit(String text) async {
    connector.body.add(utf8.encode(text));
    await pumpEventQueue();
  }

  /// Pushes raw [bytes], for the split-codepoint cases.
  Future<void> emitBytes(List<int> bytes) async {
    connector.body.add(bytes);
    await pumpEventQueue();
  }

  Future<void> closeBody() async {
    await connector.body.close();
    await pumpEventQueue();
  }

  Future<void> errorBody(Object error) async {
    connector.body.addError(error);
    await pumpEventQueue();
  }

  List<AiChatErrorEvent> get errors =>
      events.whereType<AiChatErrorEvent>().toList();

  Future<void> tearDown() async {
    await subscription.cancel();
    await source.dispose();
  }
}

void main() {
  group('authentication', () {
    test('attaches the token as the Sanad-Access-Token header', () async {
      final h = _Harness(token: kProbeToken);
      addTearDown(h.tearDown);

      await h.send('hello');

      expect(h.connector.request.headers['Sanad-Access-Token'], kProbeToken);
    });

    test('never puts the token in the body', () async {
      final h = _Harness(token: kProbeToken);
      addTearDown(h.tearDown);

      await h.send('hello');

      expect(h.connector.request.body, isNot(contains(kProbeToken)));
      final decoded =
          jsonDecode(h.connector.request.body) as Map<String, dynamic>;
      expect(decoded.keys, unorderedEquals(['conversation_id', 'message']));
    });

    test('never puts the token in the URL', () async {
      final h = _Harness(token: kProbeToken);
      addTearDown(h.tearDown);

      await h.send('hello');

      expect(h.connector.request.url.toString(), isNot(contains(kProbeToken)));
      expect(h.connector.request.url, kUrl);
    });

    test('omits the header entirely when there is no session', () async {
      final h = _Harness();
      addTearDown(h.tearDown);

      await h.send('hello');

      expect(
        h.connector.request.headers.containsKey('Sanad-Access-Token'),
        isFalse,
      );
    });

    test('omits the header when the token is empty', () async {
      final h = _Harness(token: '');
      addTearDown(h.tearDown);

      await h.send('hello');

      expect(
        h.connector.request.headers.containsKey('Sanad-Access-Token'),
        isFalse,
      );
    });

    test('re-reads the token each turn, so a refresh is picked up', () async {
      final h = _Harness(token: 'first');
      addTearDown(h.tearDown);

      await h.send('one');
      h.tokens.token = 'second';
      await h.send('two');

      expect(h.connector.requests[0].headers['Sanad-Access-Token'], 'first');
      expect(h.connector.requests[1].headers['Sanad-Access-Token'], 'second');
    });

    test('no diagnostic or emitted event ever contains the token', () async {
      final h = _Harness(token: kProbeToken);
      addTearDown(h.tearDown);

      // Walk every failure path that produces output.
      h.connector.status = 500;
      await h.send('a');

      h.connector.status = 200;
      await h.send('b');
      await h.emit(startFrame());
      await h.emit('data: {not json\n\n');
      await h.errorBody(const AiChatSseTimeout());
      await h.closeBody();

      h.connector.throwOnOpen = Exception('boom $kProbeToken');
      await h.send('c');

      expect(h.diagnostics.text, isNot(contains(kProbeToken)));
      expect(h.diagnostics.diagnostics, isNotEmpty);
      for (final event in h.events) {
        expect(jsonEncode(event.toJson()), isNot(contains(kProbeToken)));
      }
    });
  });

  group('request shape', () {
    test('sends exactly conversation_id and message', () async {
      final h = _Harness();
      addTearDown(h.tearDown);

      await h.send('  book me a service  ');

      expect(
        jsonDecode(h.connector.request.body),
        <String, dynamic>{
          'conversation_id': kConversationId,
          'message': '  book me a service  ',
        },
      );
    });

    test('asks for an event stream and sends JSON', () async {
      final h = _Harness();
      addTearDown(h.tearDown);

      await h.send('hello');

      expect(h.connector.request.headers['Accept'], 'text/event-stream');
      expect(h.connector.request.headers['Content-Type'], 'application/json');
    });

    test('carries the same conversation id across turns', () async {
      final h = _Harness();
      addTearDown(h.tearDown);

      await h.send('one');
      await h.emit(startFrame());
      await h.emit(endFrame('a', 1));
      await h.send('two');

      for (final request in h.connector.requests) {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['conversation_id'], kConversationId);
      }
    });

    test('opens one request per turn', () async {
      final h = _Harness();
      addTearDown(h.tearDown);

      await h.send('one');
      await h.emit(startFrame());
      await h.emit(endFrame('a', 1));
      await h.send('two');

      expect(h.connector.requests, hasLength(2));
    });
  });

  group('protocol events', () {
    test('decodes a full turn in order', () async {
      final h = _Harness();
      addTearDown(h.tearDown);

      await h.send('hi');
      await h.emit(startFrame());
      await h.emit(deltaFrame('Hel', 1));
      await h.emit(deltaFrame('lo', 2));
      await h.emit(endFrame('Hello', 3));

      expect(h.events.map((e) => e.type), [
        AiChatEventType.messageStart,
        AiChatEventType.textDelta,
        AiChatEventType.textDelta,
        AiChatEventType.messageEnd,
      ]);
      expect((h.events[1] as AiChatTextDeltaEvent).delta, 'Hel');
      expect((h.events[3] as AiChatMessageEndEvent).text, 'Hello');
    });

    test('preserves seq, messageId and conversationId', () async {
      final h = _Harness();
      addTearDown(h.tearDown);

      await h.send('hi');
      await h.emit(deltaFrame('x', 7));

      expect(h.events.single.seq, 7);
      expect(h.events.single.messageId, 'msg_1');
      expect(h.events.single.conversationId, kConversationId);
    });

    test('decodes several frames arriving in one chunk', () async {
      final h = _Harness();
      addTearDown(h.tearDown);

      await h.send('hi');
      await h.emit(startFrame() + deltaFrame('a', 1) + endFrame('a', 2));

      expect(h.events, hasLength(3));
    });

    test('decodes a frame split across chunks', () async {
      final h = _Harness();
      addTearDown(h.tearDown);

      final wire = deltaFrame('hello', 1);
      await h.send('hi');
      await h.emit(wire.substring(0, 20));
      expect(h.events, isEmpty);
      await h.emit(wire.substring(20));

      expect((h.events.single as AiChatTextDeltaEvent).delta, 'hello');
    });

    test('Arabic split mid-codepoint arrives intact', () async {
      final h = _Harness();
      addTearDown(h.tearDown);

      final bytes = utf8.encode(deltaFrame('مرحبا بك', 1));
      await h.send('hi');
      // Split inside the multi-byte run.
      await h.emitBytes(bytes.sublist(0, bytes.length - 12));
      await h.emitBytes(bytes.sublist(bytes.length - 12));

      expect((h.events.single as AiChatTextDeltaEvent).delta, 'مرحبا بك');
    });

    test('a ui frame after message_end still decodes', () async {
      final h = _Harness();
      addTearDown(h.tearDown);

      await h.send('hi');
      await h.emit(startFrame());
      await h.emit(endFrame('done', 1));
      await h.emit(
        frame(
          envelope(
            type: 'ui',
            eventId: 'evt_ui',
            seq: 2,
            payload: const {
              'schemaVersion': 1,
              'blocks': [
                {'type': 'text', 'text': 'hi'},
              ],
            },
          ),
        ),
      );

      final ui = h.events.last as AiChatUiEvent;
      expect(ui.payload['schemaVersion'], 1);
      // The transport hands the payload through raw: validation is the bloc's
      // job, at ingestion.
      expect(ui.payload['blocks'], isA<List<dynamic>>());
    });

    test('a typing frame decodes', () async {
      final h = _Harness();
      addTearDown(h.tearDown);

      await h.send('hi');
      await h.emit(
        frame(
          envelope(
            type: 'typing',
            eventId: 'evt_t',
            messageId: null,
            payload: const {'active': true},
          ),
        ),
      );

      expect((h.events.single as AiChatTypingEvent).active, isTrue);
    });

    test('an agent error frame is surfaced verbatim', () async {
      final h = _Harness();
      addTearDown(h.tearDown);

      await h.send('hi');
      await h.emit(
        frame(
          envelope(
            type: 'error',
            eventId: 'evt_e',
            messageId: null,
            payload: const {'code': 'rate_limited', 'message': 'Slow down.'},
          ),
        ),
      );

      final error = h.events.single as AiChatErrorEvent;
      expect(error.code, 'rate_limited');
      expect(error.message, 'Slow down.');
    });

    test('an unknown event type is dropped, not fatal', () async {
      final h = _Harness();
      addTearDown(h.tearDown);

      await h.send('hi');
      await h.emit(frame(envelope(type: 'tool_status', eventId: 'evt_x')));
      await h.emit(deltaFrame('still here', 1));

      expect(h.events, hasLength(1));
      expect(h.diagnostics.diagnostics, isNotEmpty);
    });

    test(
      'a malformed JSON frame is dropped and the stream continues',
      () async {
        final h = _Harness();
        addTearDown(h.tearDown);

        await h.send('hi');
        await h.emit(startFrame());
        await h.emit('data: {"eventId": broken\n\n');
        await h.emit(deltaFrame('still here', 1));

        expect(h.events.map((e) => e.type), [
          AiChatEventType.messageStart,
          AiChatEventType.textDelta,
        ]);
        expect(
          h.diagnostics.diagnostics.map((d) => d.code),
          contains(AiUiDiagnosticCode.malformedPayload),
        );
      },
    );

    test('an oversized frame is dropped with a limit diagnostic', () async {
      final h = _Harness();
      addTearDown(h.tearDown);

      final huge = 'x' * (AiUiLimits.defaults.maxPayloadBytes + 100);
      await h.send('hi');
      await h.emit(deltaFrame(huge, 1));
      await h.emit(deltaFrame('small', 2));

      expect(h.events, hasLength(1));
      expect((h.events.single as AiChatTextDeltaEvent).delta, 'small');
      expect(
        h.diagnostics.diagnostics.map((d) => d.code),
        contains(AiUiDiagnosticCode.limitExceeded),
      );
    });

    test('a frame with no data line produces nothing', () async {
      final h = _Harness();
      addTearDown(h.tearDown);

      await h.send('hi');
      await h.emit(': keepalive\n\nevent: ping\n\n');

      expect(h.events, isEmpty);
    });
  });

  group('HTTP errors', () {
    test('a 422 emits one status-coded error and no protocol events', () async {
      final h = _Harness();
      addTearDown(h.tearDown);

      h.connector.status = 422;
      await h.send('hi');

      expect(h.errors, hasLength(1));
      expect(h.errors.single.code, 'http_422');
      expect(h.errors.single.message, 'ai_chat.transport_request_failed');
    });

    test('a 500 emits one status-coded error', () async {
      final h = _Harness();
      addTearDown(h.tearDown);

      h.connector.status = 500;
      await h.send('hi');

      expect(h.errors.single.code, 'http_500');
    });

    test('the response body is never read on a non-2xx', () async {
      final h = _Harness();
      addTearDown(h.tearDown);

      h.connector.status = 422;
      await h.send('hi');

      // The body was never subscribed to, so nothing Pydantic-shaped can
      // reach a diagnostic or the user.
      expect(h.connector.body.hasListener, isFalse);
      expect(h.diagnostics.text, contains('http 422'));
      expect(h.diagnostics.text, isNot(contains('detail')));
    });

    test(
      'a connect failure emits connection_failed without throwing',
      () async {
        final h = _Harness();
        addTearDown(h.tearDown);

        h.connector.throwOnOpen = Exception('no route to host');
        await h.send('hi');

        expect(h.errors.single.code, 'connection_failed');
        expect(h.errors.single.message, 'ai_chat.transport_connection_failed');
        // Only the type reaches the diagnostic, never the message.
        expect(h.diagnostics.text, isNot(contains('no route to host')));
      },
    );

    test('a connect timeout emits the timeout message', () async {
      final h = _Harness();
      addTearDown(h.tearDown);

      h.connector.throwOnOpen = const AiChatSseTimeout();
      await h.send('hi');

      expect(h.errors.single.code, 'timeout');
      expect(h.errors.single.message, 'ai_chat.transport_timeout');
    });

    test('a later turn still works after a failed one', () async {
      final h = _Harness();
      addTearDown(h.tearDown);

      h.connector.throwOnOpen = Exception('flaky');
      await h.send('one');
      h.connector.throwOnOpen = null;
      await h.send('two');
      await h.emit(deltaFrame('recovered', 1));

      expect(
        h.events.whereType<AiChatTextDeltaEvent>().single.delta,
        'recovered',
      );
    });
  });

  group('stream failures', () {
    test('a receive timeout emits exactly one timeout error', () async {
      final h = _Harness();
      addTearDown(h.tearDown);

      await h.send('hi');
      await h.emit(startFrame());
      await h.errorBody(const AiChatSseTimeout());
      await h.closeBody();

      expect(h.errors, hasLength(1));
      expect(h.errors.single.code, 'timeout');
      expect(h.errors.single.message, 'ai_chat.transport_timeout');
    });

    test('a stream cut after message_start emits stream_interrupted', () async {
      final h = _Harness();
      addTearDown(h.tearDown);

      await h.send('hi');
      await h.emit(startFrame());
      await h.emit(deltaFrame('half a sen', 1));
      await h.closeBody();

      expect(h.errors, hasLength(1));
      expect(h.errors.single.code, 'stream_interrupted');
      expect(h.errors.single.message, 'ai_chat.transport_stream_interrupted');
    });

    test('a completed turn emits no transport error', () async {
      final h = _Harness();
      addTearDown(h.tearDown);

      await h.send('hi');
      await h.emit(startFrame());
      await h.emit(endFrame('all done', 1));
      await h.closeBody();

      expect(h.errors, isEmpty);
    });

    test('a stream error after message_end emits no error bubble', () async {
      final h = _Harness();
      addTearDown(h.tearDown);

      await h.send('hi');
      await h.emit(startFrame());
      await h.emit(endFrame('all done', 1));
      await h.errorBody(Exception('socket reset on close'));
      await h.closeBody();

      expect(h.errors, isEmpty);
    });

    test('an unterminated final frame is reported and not decoded', () async {
      final h = _Harness();
      addTearDown(h.tearDown);

      await h.send('hi');
      await h.emit(startFrame());
      await h.emit(endFrame('done', 1));
      await h.emit('data: {"eventId":"evt_trunc","type":"text_del');
      await h.closeBody();

      expect(h.events.map((e) => e.type), [
        AiChatEventType.messageStart,
        AiChatEventType.messageEnd,
      ]);
      expect(h.diagnostics.text, contains('discarded incomplete frame'));
    });

    test('a 200 with an empty body emits nothing and does not hang', () async {
      // Reproduced live: an empty `message` returns 200 text/event-stream with
      // no frames at all.
      final h = _Harness();
      addTearDown(h.tearDown);

      await h.send('hi');
      await h.closeBody();

      expect(h.events, isEmpty);
      expect(h.diagnostics.text, contains('stream closed with no frames'));
    });
  });

  group('lifecycle', () {
    test('a new turn cancels the one in flight', () async {
      final h = _Harness();
      addTearDown(h.tearDown);

      await h.send('one');
      await h.emit(startFrame());
      await h.send('two');

      expect(h.connector.requests[0].cancellation.isCancelled, isTrue);
      expect(h.connector.requests[1].cancellation.isCancelled, isFalse);
    });

    test('a replaced turn emits no interruption error', () async {
      final h = _Harness();
      addTearDown(h.tearDown);

      await h.send('one');
      await h.emit(startFrame());
      await h.send('two');
      await pumpEventQueue();

      // Cancelling our own turn is not a failure and must not surface as one.
      expect(h.errors, isEmpty);
    });

    test('a replaced turn stops delivering its events', () async {
      final h = _Harness();
      addTearDown(h.tearDown);

      await h.send('one');
      final firstBody = h.connector.body;
      await h.emit(startFrame());
      await h.send('two');

      firstBody.add(utf8.encode(deltaFrame('from the old turn', 9)));
      await pumpEventQueue();

      expect(
        h.events.whereType<AiChatTextDeltaEvent>(),
        isEmpty,
        reason: 'the cancelled turn must not write into the new bubble',
      );
    });

    test('dispose cancels the in-flight request', () async {
      final h = _Harness();

      await h.send('hi');
      await h.emit(startFrame());
      await h.source.dispose();

      expect(h.connector.request.cancellation.isCancelled, isTrue);
      await h.subscription.cancel();
    });

    test('dispose closes the event stream', () async {
      final h = _Harness();

      await h.send('hi');
      await h.source.dispose();

      expect(h.source.events, emitsDone);
      await h.subscription.cancel();
    });

    test('dispose is idempotent', () async {
      final h = _Harness();

      await h.send('hi');
      await h.source.dispose();
      await h.source.dispose();
      await h.source.dispose();

      await h.subscription.cancel();
    });

    test('dispose before any send is safe', () async {
      final h = _Harness();

      await h.source.dispose();

      expect(h.connector.requests, isEmpty);
      await h.subscription.cancel();
    });

    test('send after dispose is a no-op', () async {
      final h = _Harness();

      await h.source.dispose();
      await h.send('hi');

      expect(h.connector.requests, isEmpty);
      expect(h.events, isEmpty);
      await h.subscription.cancel();
    });

    test('a stream closing after dispose emits nothing', () async {
      final h = _Harness();

      await h.send('hi');
      await h.emit(startFrame());
      final body = h.connector.body;
      await h.source.dispose();

      // The socket is torn down after we walked away; no error bubble is due.
      if (!body.isClosed) await body.close();
      await pumpEventQueue();

      expect(h.events.whereType<AiChatErrorEvent>(), isEmpty);
      await h.subscription.cancel();
    });

    test('dispose during a pending connect cancels it', () async {
      final h = _Harness();

      h.connector.gate = Completer<void>();
      final pending = h.send('hi');
      await pumpEventQueue();

      await h.source.dispose();
      h.connector.gate!.complete();
      await pending;

      expect(h.connector.request.cancellation.isCancelled, isTrue);
      expect(h.events, isEmpty);
      await h.subscription.cancel();
    });
  });
}
