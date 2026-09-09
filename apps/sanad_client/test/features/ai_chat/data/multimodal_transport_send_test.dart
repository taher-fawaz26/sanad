import 'dart:async';
import 'dart:convert';

import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network/network.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/sse_ai_chat_event_source.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/websocket_ai_chat_event_source.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/entities/ai_chat_attachment.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/entities/ai_outgoing_message.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/entities/ai_uploaded_attachment.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_attachment_uploader.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../support/attachment_fixtures.dart';

/// A token that must never appear anywhere but the request header.
const String kProbeToken = 'tok_SECRET_c0ffee_do_not_leak';
const String kConversationId = 'conv_multimodal_1';
final Uri kStreamUrl = Uri.parse(
  'https://agent.example/user-agent/chat/stream',
);
final Uri kSocketUrl = Uri.parse('wss://agent.example/agent/chat/ws');

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
  Future<String> refreshAccessToken() async => throw UnimplementedError();
}

/// Stands in for the upload pipeline. Records what it was handed so a test can
/// prove the transport asked before it sent.
class _FakeUploader implements AiAttachmentUploader {
  _FakeUploader({this.failWith});

  /// When set, every batch fails with this key.
  final String? failWith;

  final List<List<AiChatAttachment>> batches = <List<AiChatAttachment>>[];

  @override
  Future<AiAttachmentUploadResult> upload(
    List<AiChatAttachment> attachments,
  ) async {
    batches.add(attachments);
    final key = failWith;
    if (key != null) return AiAttachmentUploadFailed(key);

    return AiAttachmentsUploaded([
      for (final a in attachments)
        AiUploadedAttachment(
          source: a,
          mediaId: 'upl_${a.id}',
          url: 'https://cdn.invalid/upl_${a.id}',
        ),
    ]);
  }
}

class _FakeConnector {
  final List<AiChatSseRequest> requests = <AiChatSseRequest>[];
  final List<StreamController<List<int>>> bodies =
      <StreamController<List<int>>>[];

  Future<AiChatSseResponse> call(AiChatSseRequest request) async {
    requests.add(request);
    final body = StreamController<List<int>>();
    bodies.add(body);
    return AiChatSseResponse(statusCode: 200, body: body.stream);
  }

  AiChatSseRequest get request => requests.last;
}

class _FakeChannel extends StreamChannelMixin<dynamic>
    implements WebSocketChannel {
  final StreamController<dynamic> _incoming = StreamController<dynamic>();
  final List<String> sent = <String>[];
  late final _FakeSink _sink = _FakeSink(this);

  @override
  Stream<dynamic> get stream => _incoming.stream;

  @override
  WebSocketSink get sink => _sink;

  @override
  Future<void> get ready => Future<void>.value();

  @override
  String? get protocol => null;

  @override
  int? get closeCode => null;

  @override
  String? get closeReason => null;
}

class _FakeSink implements WebSocketSink {
  _FakeSink(this._channel);

  final _FakeChannel _channel;

  @override
  void add(dynamic data) => _channel.sent.add(data as String);

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    await _channel._incoming.close();
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<dynamic> stream) async {}

  @override
  Future<void> get done => Future<void>.value();
}

// ─── harnesses ──────────────────────────────────────────────────────────────

/// One send path, whichever transport implements it.
///
/// The two transports must agree on the body byte for byte, so every
/// expectation below is written once and run against both.
abstract class _Transport {
  List<AiChatEvent> get events;
  List<String> get bodies;
  Map<String, String> get headers;
  Future<void> send(String text);
  Future<void> sendMultimodal(AiOutgoingMessage message);
  Future<void> sendInteraction(
    AiUiInteraction interaction, {
    required String text,
  });
  Future<void> dispose();

  String get body => bodies.last;
  Map<String, dynamic> get decoded => jsonDecode(body) as Map<String, dynamic>;
  List<AiChatErrorEvent> get errors =>
      events.whereType<AiChatErrorEvent>().toList();
}

class _SseTransport extends _Transport {
  _SseTransport({AiAttachmentUploader? uploader, String? token}) {
    _source = SseAiChatEventSource(
      url: kStreamUrl,
      tokenManager: _FakeTokenManager(token: token),
      conversationId: kConversationId,
      connector: _connector.call,
      uploader: uploader ?? const AiUnavailableAttachmentUploader(),
    );
    _subscription = _source.events.listen(events.add);
  }

  final _FakeConnector _connector = _FakeConnector();
  late final SseAiChatEventSource _source;
  late final StreamSubscription<AiChatEvent> _subscription;

  @override
  final List<AiChatEvent> events = <AiChatEvent>[];

  @override
  List<String> get bodies => [for (final r in _connector.requests) r.body];

  @override
  Map<String, String> get headers => _connector.request.headers;

  @override
  Future<void> send(String text) async {
    await _source.send(text);
    await pumpEventQueue();
  }

  @override
  Future<void> sendMultimodal(AiOutgoingMessage message) async {
    await _source.sendMultimodal(message);
    await pumpEventQueue();
  }

  @override
  Future<void> sendInteraction(
    AiUiInteraction interaction, {
    required String text,
  }) async {
    await _source.sendInteraction(interaction, text: text);
    await pumpEventQueue();
  }

  @override
  Future<void> dispose() async {
    await _subscription.cancel();
    await _source.dispose();
  }
}

class _WebSocketTransport extends _Transport {
  _WebSocketTransport({AiAttachmentUploader? uploader, String? token}) {
    _source = WebSocketAiChatEventSource(
      url: kSocketUrl,
      tokenManager: _FakeTokenManager(token: token),
      conversationId: kConversationId,
      connector: (_, headers) {
        _headers = headers;
        return _channel;
      },
      uploader: uploader ?? const AiUnavailableAttachmentUploader(),
    );
    _subscription = _source.events.listen(events.add);
  }

  final _FakeChannel _channel = _FakeChannel();
  Map<String, String> _headers = const {};
  late final WebSocketAiChatEventSource _source;
  late final StreamSubscription<AiChatEvent> _subscription;

  @override
  final List<AiChatEvent> events = <AiChatEvent>[];

  @override
  List<String> get bodies => _channel.sent;

  @override
  Map<String, String> get headers => _headers;

  @override
  Future<void> send(String text) async {
    await _source.send(text);
    await pumpEventQueue();
  }

  @override
  Future<void> sendMultimodal(AiOutgoingMessage message) async {
    await _source.sendMultimodal(message);
    await pumpEventQueue();
  }

  @override
  Future<void> sendInteraction(
    AiUiInteraction interaction, {
    required String text,
  }) async {
    await _source.sendInteraction(interaction, text: text);
    await pumpEventQueue();
  }

  @override
  Future<void> dispose() async {
    await _subscription.cancel();
    await _source.dispose();
  }
}

/// One answer, shared by both transports' cases.
const _interaction = AiUiInteraction(
  interactionId: 'int_1',
  nodeId: 'slots_1',
  nodeType: AiUiNodeType.timeSlots,
  messageId: 'msg_7',
  kind: AiUiInteractionKind.slotSelected,
  value: AiUiSelectionValue(id: 's_0900', label: '9:00 AM'),
  text: 'Book me the 9:00 AM slot',
);

void main() {
  final transports =
      <
        String,
        _Transport Function({
          AiAttachmentUploader? uploader,
          String? token,
        })
      >{
        'SSE': ({uploader, token}) =>
            _SseTransport(uploader: uploader, token: token),
        'WebSocket': ({uploader, token}) =>
            _WebSocketTransport(uploader: uploader, token: token),
      };

  for (final MapEntry(key: name, value: build) in transports.entries) {
    group('$name: a multimodal turn', () {
      test('uploads before it sends, and sends the {id, url} pair', () async {
        final uploader = _FakeUploader();
        final transport = build(uploader: uploader);
        addTearDown(transport.dispose);

        await transport.sendMultimodal(
          AiOutgoingMessage(
            text: 'what does this say?',
            attachments: [imageFixture(id: 'a1')],
          ),
        );

        expect(uploader.batches.single.single.id, 'a1');
        expect(transport.decoded, <String, dynamic>{
          'conversation_id': kConversationId,
          'message': 'what does this say?',
          'attachments': [
            <String, dynamic>{
              'id': 'upl_a1',
              'url': 'https://cdn.invalid/upl_a1',
            },
          ],
        });
      });

      test('a voice note travels as one message with its words', () async {
        final transport = build(uploader: _FakeUploader());
        addTearDown(transport.dispose);

        await transport.sendMultimodal(
          AiOutgoingMessage(
            attachments: [
              audioFixture(id: 'v1', transcript: 'book me a plumber'),
            ],
          ),
        );

        final body = transport.decoded;
        final attachments = body['attachments'] as List<dynamic>;
        expect(body['message'], 'book me a plumber');
        expect(attachments.single, <String, dynamic>{
          'id': 'upl_v1',
          'url': 'https://cdn.invalid/upl_v1',
          'type': 'audio',
          'transcript': 'book me a plumber',
        });
        // One request, one message — never a second turn for the transcript.
        expect(transport.bodies, hasLength(1));
      });

      test('a text-only turn is identical to a plain send', () async {
        final viaSend = build(uploader: _FakeUploader());
        addTearDown(viaSend.dispose);
        final viaMultimodal = build(uploader: _FakeUploader());
        addTearDown(viaMultimodal.dispose);

        await viaSend.send('hello');
        await viaMultimodal.sendMultimodal(
          const AiOutgoingMessage(text: 'hello'),
        );

        expect(viaMultimodal.body, viaSend.body);
      });

      test('the token stays out of the body', () async {
        final transport = build(uploader: _FakeUploader(), token: kProbeToken);
        addTearDown(transport.dispose);

        await transport.sendMultimodal(
          AiOutgoingMessage(
            text: 'look',
            attachments: [imageFixture()],
          ),
        );

        expect(transport.body, isNot(contains(kProbeToken)));
        expect(transport.headers['Sanad-Access-Token'], kProbeToken);
      });
    });

    group('$name: when the upload fails', () {
      test('nothing is sent', () async {
        // A turn naming an attachment the agent cannot fetch is worse than one
        // never sent: the model answers about something it could not read.
        final transport = build(
          uploader: _FakeUploader(failWith: 'ai_chat.attachment_upload_failed'),
        );
        addTearDown(transport.dispose);

        await transport.sendMultimodal(
          AiOutgoingMessage(text: 'look', attachments: [imageFixture()]),
        );

        expect(transport.bodies, isEmpty);
      });

      test('exactly one error reaches the conversation', () async {
        final transport = build(
          uploader: _FakeUploader(failWith: 'ai_chat.attachment_upload_failed'),
        );
        addTearDown(transport.dispose);

        await transport.sendMultimodal(
          AiOutgoingMessage(text: 'look', attachments: [imageFixture()]),
        );

        expect(transport.errors, hasLength(1));
        expect(transport.errors.single.code, 'attachment_upload_failed');
        expect(
          transport.errors.single.message,
          'ai_chat.attachment_upload_failed',
        );
      });
    });

    group('$name: without an uploader', () {
      test('a text turn still goes out', () async {
        // The default `AiUnavailableAttachmentUploader` succeeds trivially for
        // an empty batch, which is what keeps every construction site that
        // never passed one behaving exactly as before.
        final transport = build();
        addTearDown(transport.dispose);

        await transport.sendMultimodal(const AiOutgoingMessage(text: 'hello'));

        expect(transport.decoded['message'], 'hello');
      });

      test('attachments are refused rather than silently dropped', () async {
        final transport = build();
        addTearDown(transport.dispose);

        await transport.sendMultimodal(
          AiOutgoingMessage(text: 'look', attachments: [imageFixture()]),
        );

        expect(transport.bodies, isEmpty);
        expect(transport.errors, hasLength(1));
      });
    });

    group('$name: an interaction turn', () {
      test('carries the structured answer beside the sentence', () async {
        final transport = build();
        addTearDown(transport.dispose);

        await transport.sendInteraction(
          _interaction,
          text: 'Book me the 9:00 AM slot',
        );

        expect(transport.decoded, <String, dynamic>{
          'conversation_id': kConversationId,
          'message': 'Book me the 9:00 AM slot',
          'interaction': <String, dynamic>{
            'interactionId': 'int_1',
            'nodeId': 'slots_1',
            'nodeType': 'time_slots',
            'messageId': 'msg_7',
            'kind': 'slot_selected',
            'status': 'submitted',
            'value': <String, dynamic>{'id': 's_0900', 'label': '9:00 AM'},
            'text': 'Book me the 9:00 AM slot',
          },
        });
      });

      test('uploads nothing — an answer carries no files', () async {
        final uploader = _FakeUploader();
        final transport = build(uploader: uploader);
        addTearDown(transport.dispose);

        await transport.sendInteraction(_interaction, text: 'x');

        expect(uploader.batches, isEmpty);
      });

      test('the token stays out of the body', () async {
        final transport = build(token: 'sanad-secret-token');
        addTearDown(transport.dispose);

        await transport.sendInteraction(
          _interaction,
          text: 'Book me the 9:00 AM slot',
        );

        expect(transport.bodies.single, isNot(contains('sanad-secret-token')));
      });

      test('a cancellation travels with its status intact', () async {
        final transport = build();
        addTearDown(transport.dispose);

        await transport.sendInteraction(
          _interaction.withStatus(AiUiInteractionStatus.cancelled),
          text: 'Skipped for now.',
        );

        final interaction =
            transport.decoded['interaction']! as Map<String, dynamic>;
        expect(interaction['status'], 'cancelled');
      });
    });

    group('$name: after disposal', () {
      test('a multimodal turn uploads nothing and sends nothing', () async {
        final uploader = _FakeUploader();
        final transport = build(uploader: uploader);

        await transport.dispose();
        await transport.sendMultimodal(
          AiOutgoingMessage(text: 'look', attachments: [imageFixture()]),
        );

        expect(uploader.batches, isEmpty);
        expect(transport.bodies, isEmpty);
      });

      test('an interaction sends nothing', () async {
        final transport = build();

        await transport.dispose();
        await transport.sendInteraction(_interaction, text: 'x');

        expect(transport.bodies, isEmpty);
      });
    });
  }
}
