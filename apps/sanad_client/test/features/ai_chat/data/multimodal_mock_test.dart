import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network/network.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/mock_ai_chat_event_source.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/mocks/multimodal_mock_scenarios.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/sse_ai_chat_event_source.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/websocket_ai_chat_event_source.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/ai_chat_event_source.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/ai_multimodal_event_source.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/entities/ai_outgoing_message.dart';

import '../support/attachment_fixtures.dart';

void main() {
  group('the multimodal capability is opt-in', () {
    test('the mock implements both interfaces', () {
      final source = MockAiChatEventSource();
      addTearDown(source.dispose);

      expect(source, isA<AiChatEventSource>());
      expect(source, isA<AiMultimodalEventSource>());
    });

    test('the SSE transport has opted in', () {
      // The capability is still a separate interface for the original reason:
      // a member on `AiChatEventSource` would not have been inherited — every
      // source `implements` it — so it would have been a compile error in all
      // three rather than something a transport could choose. What changed is
      // that this transport chose it.
      expect(
        SseAiChatEventSource,
        isNot(AiMultimodalEventSource),
        reason: 'sanity: distinct types',
      );

      final Object source = SseAiChatEventSource(
        url: Uri.parse('https://example.invalid/stream'),
        tokenManager: _NullTokenManager(),
        conversationId: 'c',
        connector: (_) async => throw StateError('never opened'),
      );
      expect(source, isA<AiMultimodalEventSource>());
    });

    test('the WebSocket transport has opted in', () {
      final Object source = WebSocketAiChatEventSource(
        url: Uri.parse('wss://example.invalid/ws'),
        tokenManager: _NullTokenManager(),
        conversationId: 'c',
        connector: (_, _) => throw StateError('never opened'),
      );
      expect(source, isA<AiMultimodalEventSource>());
    });

    test('a source that has not opted in is still a valid event source', () {
      // The fallback branch in `AiChatBloc` exists for exactly this shape, and
      // would otherwise have no regression test now that every shipped source
      // implements the marker.
      final Object source = _TextOnlySource();

      expect(source, isA<AiChatEventSource>());
      expect(source, isNot(isA<AiMultimodalEventSource>()));
    });
  });

  group('mocked replies are about the attachments', () {
    test('one image is named', () {
      final text = MultimodalMockScenarios.describe(
        AiOutgoingMessage(attachments: [imageFixture(fileName: 'receipt.jpg')]),
      );

      expect(text, contains('receipt.jpg'));
    });

    test('several images are counted', () {
      final text = MultimodalMockScenarios.describe(
        AiOutgoingMessage(
          attachments: [
            imageFixture(id: 'a'),
            imageFixture(id: 'b'),
            imageFixture(id: 'c'),
          ],
        ),
      );

      expect(text, contains('3 images'));
    });

    test('a document is named and sized', () {
      final text = MultimodalMockScenarios.describe(
        AiOutgoingMessage(
          attachments: [
            documentFixture(fileName: 'policy.pdf', sizeBytes: 2 * 1024 * 1024),
          ],
        ),
      );

      expect(text, contains('policy.pdf'));
      expect(text, contains('2.0 MB'));
    });

    test('a recording reads its length back', () {
      final text = MultimodalMockScenarios.describe(
        AiOutgoingMessage(
          attachments: [
            audioFixture(duration: const Duration(seconds: 78)),
          ],
        ),
      );

      expect(text, contains('1:18'));
    });

    test('a mixed turn acknowledges every kind', () {
      final text = MultimodalMockScenarios.describe(
        AiOutgoingMessage(
          text: 'compare these',
          attachments: [imageFixture(), documentFixture(), audioFixture()],
        ),
      );

      expect(text, contains('photo.jpg'));
      expect(text, contains('report.pdf'));
      expect(text, contains('recording'));
      expect(text, contains('compare these'));
    });

    test('an attachment with no caption asks what to do', () {
      final text = MultimodalMockScenarios.describe(
        AiOutgoingMessage(attachments: [imageFixture()]),
      );

      expect(text, contains('What would you like me to do'));
    });

    test('it is deterministic', () {
      final message = AiOutgoingMessage(
        text: 'hi',
        attachments: [imageFixture(), audioFixture()],
      );

      expect(
        MultimodalMockScenarios.describe(message),
        MultimodalMockScenarios.describe(message),
      );
    });
  });

  group('the mock replays a multimodal turn on the real event path', () {
    test('an image turn streams a reply that names the file', () async {
      final source = MockAiChatEventSource(
        deltaDelay: Duration.zero,
        eventDelay: Duration.zero,
        thinkingDelay: Duration.zero,
      );
      addTearDown(source.dispose);

      final events = <AiChatEvent>[];
      final sub = source.events.listen(events.add);

      await source.sendMultimodal(
        AiOutgoingMessage(
          text: 'what is this?',
          attachments: [imageFixture(fileName: 'bill.png')],
        ),
      );
      await pumpEventQueue();

      // The same envelope sequence a real transport produces: nothing about
      // the attachment path bypasses the protocol.
      expect(events.whereType<AiChatMessageStartEvent>(), hasLength(1));
      expect(events.whereType<AiChatTextDeltaEvent>(), isNotEmpty);

      final end = events.whereType<AiChatMessageEndEvent>().single;
      expect(end.text, contains('bill.png'));
      expect(end.text, contains('what is this?'));

      await sub.cancel();
    });

    test('an audio-only turn still produces a reply', () async {
      final source = MockAiChatEventSource(
        deltaDelay: Duration.zero,
        eventDelay: Duration.zero,
        thinkingDelay: Duration.zero,
      );
      addTearDown(source.dispose);

      final events = <AiChatEvent>[];
      final sub = source.events.listen(events.add);

      await source.sendMultimodal(
        AiOutgoingMessage(
          attachments: [audioFixture(duration: const Duration(seconds: 5))],
        ),
      );
      await pumpEventQueue();

      expect(
        events.whereType<AiChatMessageEndEvent>().single.text,
        contains('0:05'),
      );

      await sub.cancel();
    });

    test('a text-only turn still uses the keyword scenarios', () async {
      final source = MockAiChatEventSource(
        deltaDelay: Duration.zero,
        eventDelay: Duration.zero,
        thinkingDelay: Duration.zero,
      );
      addTearDown(source.dispose);

      final events = <AiChatEvent>[];
      final sub = source.events.listen(events.add);

      await source.send('hello');
      await pumpEventQueue();

      // `hello` matches the plain-text scenario, exactly as before.
      expect(events.whereType<AiChatMessageEndEvent>(), hasLength(1));
      expect(
        events.whereType<AiChatMessageEndEvent>().single.text,
        isNot(contains('I received')),
      );

      await sub.cancel();
    });

    test('the dev scenario picker still wins over a multimodal turn', () async {
      final source = MockAiChatEventSource(
        deltaDelay: Duration.zero,
        eventDelay: Duration.zero,
        thinkingDelay: Duration.zero,
      )..forcedScenarioId = 'malformed';
      addTearDown(source.dispose);

      final events = <AiChatEvent>[];
      final sub = source.events.listen(events.add);

      await source.sendMultimodal(
        AiOutgoingMessage(attachments: [imageFixture()]),
      );
      await pumpEventQueue();

      // The hostile payloads must stay reachable whatever is attached.
      expect(events.whereType<AiChatUiEvent>(), isNotEmpty);

      await sub.cancel();
    });

    test('sending after dispose is still a no-op', () async {
      final source = MockAiChatEventSource();
      await source.dispose();

      await source.sendMultimodal(
        AiOutgoingMessage(attachments: [imageFixture()]),
      );
    });
  });
}

/// The transports need a token manager to construct; none of these tests opens
/// a connection, so it never has to return anything real.
class _NullTokenManager implements TokenManager {
  @override
  String? get accessToken => null;

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

/// A transport with no multimodal contract, kept so the fallback path in
/// `AiChatBloc` keeps a type that exercises it.
class _TextOnlySource implements AiChatEventSource {
  @override
  Stream<AiChatEvent> get events => const Stream<AiChatEvent>.empty();

  @override
  Future<void> send(String text) async {}

  @override
  Future<void> dispose() async {}
}
