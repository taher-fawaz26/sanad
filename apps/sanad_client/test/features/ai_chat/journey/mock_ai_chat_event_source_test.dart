import 'dart:async';

import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/journey/ai_journey_stage.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/mock_ai_chat_event_source.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/entities/ai_chat_attachment.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/entities/ai_outgoing_message.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/entities/chat_context_content.dart';

import 'journey_test_support.dart';

void main() {
  late MockAiChatEventSource source;
  late List<AiChatEvent> events;
  late List<ChatContextContent?> context;

  setUp(() {
    // Zero delays: the pacing is for a human watching, and a test that waited
    // for it would be slow for no signal. The *order* is what matters, and it
    // is unaffected.
    source = MockAiChatEventSource(
      deltaDelay: Duration.zero,
      eventDelay: Duration.zero,
    );
    events = [];
    context = [];
    source.events.listen(events.add);
    source.contextualContent.listen(context.add);
  });

  tearDown(() => source.dispose());

  /// Everything the source emitted, as wire type strings.
  List<String> types() => events.map((e) => e.type.wire).toList();

  Future<void> start() =>
      source.send('I need a home cleaning tomorrow at 10 AM');

  group('the envelopes match the live contract', () {
    test('one turn is typing, start, deltas, ui, end', () async {
      await start();
      await pumpEventQueue();

      expect(types().first, 'typing');
      expect(types()[1], 'message_start');
      expect(types().where((t) => t == 'text_delta'), isNotEmpty);
      final emitted = types();
      expect(emitted[emitted.length - 2], 'ui');
      expect(emitted.last, 'message_end');
    });

    test('the ui payload is a schema-versioned document of blocks', () async {
      await start();
      await pumpEventQueue();

      final ui = events.whereType<AiChatUiEvent>().single;
      expect(ui.payload['schemaVersion'], 1);
      expect(
        (ui.payload['blocks']! as List).single,
        containsPair('type', 'location_picker'),
      );
    });

    test('every event of a turn shares one message id', () async {
      await start();
      await pumpEventQueue();

      final ids = events
          .where((e) => e is! AiChatTypingEvent)
          .map((e) => e.messageId)
          .toSet();
      expect(ids, hasLength(1));
      expect(ids.single, isNotNull);
    });

    test('the deltas reconstruct the message_end text exactly', () async {
      await start();
      await pumpEventQueue();

      final streamed = events
          .whereType<AiChatTextDeltaEvent>()
          .map((e) => e.delta)
          .join();
      expect(streamed, events.whereType<AiChatMessageEndEvent>().single.text);
    });
  });

  group('it answers the structured value, not the prose', () {
    test('an interaction advances the journey', () async {
      await start();
      await source.sendInteraction(
        locationSelected(),
        // Deliberately contradictory prose: if the agent read the sentence
        // instead of the value, this turn would not advance.
        text: 'ignore me entirely',
      );
      await pumpEventQueue();

      expect(source.stage, AiJourneyStage.cameraPermissionRequired);
      expect(
        events.whereType<AiChatUiEvent>().last.payload['blocks'],
        isA<List<dynamic>>().having(
          (b) => (b.single as Map)['type'],
          'type',
          'permission_request',
        ),
      );
    });

    test('a duplicate interaction emits nothing at all', () async {
      await start();
      await source.sendInteraction(locationSelected(), text: 'x');
      await pumpEventQueue();
      final settled = events.length;

      await source.sendInteraction(locationSelected(), text: 'x');
      await pumpEventQueue();

      // Not "emits a duplicate-free reply" — emits *nothing*. A typing event
      // alone would show a thinking indicator for an answer that never comes.
      expect(events, hasLength(settled));
    });

    test('a turn carrying attachments answers the media request', () async {
      await start();
      await source.sendInteraction(locationSelected(), text: 'x');
      await source.sendInteraction(permissionResult(), text: 'x');
      await pumpEventQueue();

      await source.sendMultimodal(
        const AiOutgoingMessage(
          text: 'here they are',
          attachments: [
            AiImageAttachment(
              id: 'a1',
              fileName: 'a.jpg',
              sizeBytes: 1,
              mimeType: 'image/jpeg',
              localPath: '/tmp/a.jpg',
            ),
          ],
        ),
      );
      await pumpEventQueue();

      expect(source.stage, AiJourneyStage.providersFound);
    });
  });

  group('contextual content', () {
    test('the offer turn publishes a validated document', () async {
      await start();
      await source.sendInteraction(locationSelected(), text: 'x');
      await source.sendInteraction(permissionResult(), text: 'x');
      await source.sendInteraction(mediaResult(), text: 'x');
      await pumpEventQueue();

      final published = context.whereType<ChatContextContent>().last;
      expect(published.peekLabel, contains('8'));
      // Through the same validator the conversation's payloads go through, and
      // out the other side as protocol nodes the renderer already draws.
      expect(published.document.blocks, hasLength(2));
      expect(
        published.document.blocks.map((b) => b.type?.wire),
        ['provider_card', 'provider_card'],
      );
    });

    test('accepting the offer withdraws it', () async {
      await start();
      await source.sendInteraction(locationSelected(), text: 'x');
      await source.sendInteraction(permissionResult(), text: 'x');
      await source.sendInteraction(mediaResult(), text: 'x');
      await source.sendInteraction(offerResolved(), text: 'x');
      await pumpEventQueue();

      expect(context.last, isNull);
    });

    test('nothing is published before there is anything to offer', () async {
      await start();
      await pumpEventQueue();

      expect(context, isEmpty);
    });
  });

  group('lifecycle', () {
    test('restart forgets the journey and clears the context', () async {
      await start();
      await source.sendInteraction(locationSelected(), text: 'x');
      await pumpEventQueue();

      source.restart();
      await pumpEventQueue();

      expect(source.stage, AiJourneyStage.idle);
      expect(context.last, isNull);
    });

    test('disposing leaves no pending timers', () async {
      final paced = MockAiChatEventSource(
        deltaDelay: const Duration(milliseconds: 50),
        eventDelay: const Duration(milliseconds: 50),
      );
      unawaited(paced.send('home cleaning'));
      await paced.dispose();
      // The test framework fails on a pending timer at teardown, so reaching
      // here without one is the assertion.
      expect(paced.stage, isNotNull);
    });

    test('sending after dispose is inert', () async {
      await source.dispose();
      await source.send('home cleaning');

      expect(events, isEmpty);
    });
  });
}
