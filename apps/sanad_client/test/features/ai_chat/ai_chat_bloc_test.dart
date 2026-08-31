import 'dart:async';

import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/ai_ui_renderer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_client/src/features/ai_chat/src/ai_chat_config.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/ai_chat_event_source.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/ai_chat_message.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/actions/ai_chat_action_handlers.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/ai_chat_bloc.dart';

/// A source the test drives directly, so event ordering is explicit rather
/// than a function of timers.
class FakeEventSource implements AiChatEventSource {
  final StreamController<AiChatEvent> _controller =
      StreamController<AiChatEvent>.broadcast();
  final List<String> sent = [];
  bool disposed = false;

  @override
  Stream<AiChatEvent> get events => _controller.stream;

  @override
  Future<void> send(String text) async => sent.add(text);

  void emit(AiChatEvent event) => _controller.add(event);

  @override
  Future<void> dispose() async {
    disposed = true;
    await _controller.close();
  }
}

void main() {
  late FakeEventSource source;
  late RecordingAiUiDiagnosticsSink diagnostics;
  late AiChatBloc bloc;

  const messageId = 'msg_1';

  AiChatEvent start() =>
      const AiChatMessageStartEvent(eventId: 'e0', messageId: messageId);
  AiChatEvent delta(String text) =>
      AiChatTextDeltaEvent(eventId: 'e', messageId: messageId, delta: text);
  AiChatEvent end([String? text]) =>
      AiChatMessageEndEvent(eventId: 'e', messageId: messageId, text: text);
  AiChatEvent ui(Map<String, dynamic> payload) =>
      AiChatUiEvent(eventId: 'e', messageId: messageId, payload: payload);

  /// Lets the bloc drain its event queue.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  setUp(() {
    source = FakeEventSource();
    diagnostics = RecordingAiUiDiagnosticsSink();
    bloc = AiChatBloc(
      source: source,
      validator: AiChatConfig.validator(keepUnsupportedNodes: false),
      diagnostics: diagnostics,
    )..add(const AiChatStarted());
  });

  tearDown(() async => bloc.close());

  group('sending', () {
    test('appends a user message and forwards the text', () async {
      await settle();
      bloc.add(const AiChatMessageSubmitted('  find me a service  '));
      await settle();

      expect(bloc.state.messages, hasLength(1));
      expect(bloc.state.messages.single.role, AiChatRole.user);
      expect(bloc.state.messages.single.text, 'find me a service');
      expect(source.sent, ['find me a service']);
    });

    test('ignores an empty submission', () async {
      await settle();
      bloc.add(const AiChatMessageSubmitted('   '));
      await settle();

      expect(bloc.state.messages, isEmpty);
      expect(source.sent, isEmpty);
    });
  });

  group('streaming', () {
    test('message_start opens a streaming bubble', () async {
      await settle();
      source.emit(start());
      await settle();

      expect(bloc.state.messages.single.isStreaming, isTrue);
      expect(bloc.activeStream.messageId, messageId);
    });

    test(
      'text_delta updates the stream controller without emitting state',
      () async {
        // This is the performance contract: a token must not produce a new
        // message list, because that would rebuild every row in the chat.
        await settle();
        source.emit(start());
        await settle();

        final states = <AiChatState>[];
        final subscription = bloc.stream.listen(states.add);
        final notifications = <String>[];
        void onStream() => notifications.add(bloc.activeStream.value);
        bloc.activeStream.addListener(onStream);

        for (final word in ['I ', 'found ', '3 ', 'services']) {
          source.emit(delta(word));
        }
        await settle();

        expect(
          states,
          isEmpty,
          reason: '50 tokens must not produce 50 message-list states',
        );
        expect(notifications, hasLength(4));
        expect(bloc.activeStream.value, 'I found 3 services');

        bloc.activeStream.removeListener(onStream);
        await subscription.cancel();
      },
    );

    test('message_end takes the authoritative text', () async {
      await settle();
      source
        ..emit(start())
        ..emit(delta('I fou'));
      await settle();
      // A delta was dropped in transit; `message_end.text` repairs it rather
      // than leaving a permanently truncated bubble.
      source.emit(end('I found 3 services'));
      await settle();

      final message = bloc.state.messages.single;
      expect(message.text, 'I found 3 services');
      expect(message.status, AiChatMessageStatus.complete);
      expect(bloc.activeStream.messageId, isNull);
    });

    test('message_end falls back to accumulated text', () async {
      await settle();
      source
        ..emit(start())
        ..emit(delta('Hello'))
        ..emit(end());
      await settle();

      expect(bloc.state.messages.single.text, 'Hello');
    });
  });

  group('structured UI', () {
    test('a valid payload is parsed once and attached', () async {
      await settle();
      source
        ..emit(start())
        ..emit(
          ui({
            'schemaVersion': 1,
            'blocks': [
              {'type': 'text', 'id': 't', 'text': 'Rendered'},
            ],
          }),
        )
        ..emit(end('done'));
      await settle();

      final message = bloc.state.messages.single;
      expect(message.hasUi, isTrue);
      expect(message.document!.blocks.single, isA<AiUiTextNode>());
    });

    test('a fully rejected payload leaves the prose intact', () async {
      await settle();
      source
        ..emit(start())
        ..emit(ui({'schemaVersion': 99, 'blocks': <Object?>[]}))
        ..emit(end('Text still arrives'));
      await settle();

      final message = bloc.state.messages.single;
      expect(message.hasUi, isFalse);
      expect(message.text, 'Text still arrives');
      expect(
        diagnostics.hasCode(AiUiDiagnosticCode.unsupportedSchemaVersion),
        isTrue,
      );
    });

    test('an action outside this app is dropped before rendering', () async {
      await settle();
      source
        ..emit(start())
        ..emit(
          ui({
            'schemaVersion': 1,
            'blocks': [
              {
                'type': 'button',
                'id': 'b',
                'label': 'Open site',
                // A real protocol action, but one this app does not register.
                'action': {
                  'type': 'open_url',
                  'url': 'https://cdn.trysanad.us',
                },
              },
              {'type': 'text', 'id': 't', 'text': 'kept'},
            ],
          }),
        )
        ..emit(end('done'));
      await settle();

      final blocks = bloc.state.messages.single.document!.blocks;
      expect(blocks, hasLength(1));
      expect(blocks.single, isA<AiUiTextNode>());
      expect(
        diagnostics.hasCode(AiUiDiagnosticCode.unknownActionType),
        isTrue,
      );
    });

    test('a ui event for an unknown message changes nothing', () async {
      await settle();
      source.emit(start());
      await settle();
      source.emit(
        const AiChatUiEvent(
          eventId: 'e',
          messageId: 'msg_does_not_exist',
          payload: {
            'schemaVersion': 1,
            'blocks': [
              {'type': 'text', 'id': 't', 'text': 'orphan'},
            ],
          },
        ),
      );
      await settle();

      expect(bloc.state.messages.single.hasUi, isFalse);
    });
  });

  group('failure and lifecycle', () {
    test('an agent error marks the active message failed', () async {
      await settle();
      source
        ..emit(start())
        ..emit(delta('partial'))
        ..emit(
          const AiChatErrorEvent(
            eventId: 'e',
            code: 'rate_limited',
            message: 'Please try again shortly.',
          ),
        );
      await settle();

      expect(bloc.state.messages.single.status, AiChatMessageStatus.failed);
      expect(bloc.state.failureMessage, 'Please try again shortly.');
      expect(bloc.activeStream.messageId, isNull);
    });

    test('typing toggles without touching the message list', () async {
      await settle();
      source.emit(const AiChatTypingEvent(eventId: 'e', active: true));
      await settle();

      expect(bloc.state.isTyping, isTrue);
      expect(bloc.state.messages, isEmpty);
    });

    test('closing the bloc disposes the source', () async {
      await settle();
      await bloc.close();

      expect(source.disposed, isTrue);
    });

    test('closing twice is safe', () async {
      // tearDown closes again after this; a ValueNotifier asserts on a second
      // dispose, so close() has to be idempotent.
      await settle();
      await bloc.close();

      await expectLater(bloc.close(), completes);
    });
  });

  group('action allowlist', () {
    test('registered handlers match the declared supported set', () {
      // The pairing that makes "a button always does something" true: the
      // validator drops anything not in AiChatConfig.supportedActions, so the
      // registry must implement exactly that set — no more, no less.
      final registry = buildAiChatActionRegistry(onSendMessage: (_) {});

      expect(registry.supportedTypes, equals(AiChatConfig.supportedActions));
    });

    test('open_url and open_route are deliberately not implemented', () {
      expect(
        AiChatConfig.supportedActions,
        isNot(contains(AiUiActionType.openUrl)),
      );
      expect(
        AiChatConfig.supportedActions,
        isNot(contains(AiUiActionType.openRoute)),
      );
    });
  });
}
