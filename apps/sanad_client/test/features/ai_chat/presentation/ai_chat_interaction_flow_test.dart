import 'dart:async';

import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/ai_ui_renderer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_client/src/features/ai_chat/src/ai_chat_config.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/ai_chat_turn_payload.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/scenarios/interaction_scenarios.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/ai_chat_event_source.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/ai_chat_message.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/ai_interactive_event_source.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/actions/ai_chat_interaction_sink.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/ai_chat_bloc.dart';

/// A source that speaks the interaction contract and records what it sent.
class FakeInteractiveSource
    implements AiChatEventSource, AiInteractiveEventSource {
  final StreamController<AiChatEvent> _controller =
      StreamController<AiChatEvent>.broadcast();
  final List<String> sent = [];
  final List<AiUiInteraction> interactions = [];
  final List<String> interactionTexts = [];

  @override
  Stream<AiChatEvent> get events => _controller.stream;

  @override
  Future<void> send(String text) async => sent.add(text);

  @override
  Future<void> sendInteraction(
    AiUiInteraction interaction, {
    required String text,
  }) async {
    interactions.add(interaction);
    interactionTexts.add(text);
  }

  void emit(AiChatEvent event) => _controller.add(event);

  @override
  Future<void> dispose() async => _controller.close();
}

/// A source with no interaction contract, to prove the degradation path.
class FakePlainSource implements AiChatEventSource {
  final StreamController<AiChatEvent> _controller =
      StreamController<AiChatEvent>.broadcast();
  final List<String> sent = [];

  @override
  Stream<AiChatEvent> get events => _controller.stream;

  @override
  Future<void> send(String text) async => sent.add(text);

  @override
  Future<void> dispose() async => _controller.close();
}

void main() {
  const slotAnswer = AiUiInteraction(
    interactionId: 'int_1',
    nodeId: 'slots_1',
    nodeType: AiUiNodeType.timeSlots,
    messageId: 'msg_1',
    kind: AiUiInteractionKind.slotSelected,
    value: AiUiSelectionValue(id: 's_0900', label: '9:00 AM'),
    text: 'Book me the 9:00 AM slot',
  );

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  group('the chat bloc', () {
    late FakeInteractiveSource source;
    late AiChatBloc bloc;

    setUp(() {
      source = FakeInteractiveSource();
      bloc = AiChatBloc(
        source: source,
        validator: AiChatConfig.validator(keepUnsupportedNodes: false),
        diagnostics: const NoopAiUiDiagnosticsSink(),
      )..add(const AiChatStarted());
    });

    tearDown(() async => bloc.close());

    test('an answer becomes a visible user turn', () async {
      await settle();
      bloc.add(const AiChatInteractionSubmitted(slotAnswer));
      await settle();

      final message = bloc.state.messages.single;
      expect(message.role, AiChatRole.user);
      expect(message.text, 'Book me the 9:00 AM slot');
      expect(message.isInteraction, isTrue);
      expect(message.interaction, slotAnswer);
    });

    test('the structured answer reaches the transport', () async {
      await settle();
      bloc.add(const AiChatInteractionSubmitted(slotAnswer));
      await settle();

      expect(source.interactions.single, slotAnswer);
      expect(source.interactionTexts.single, 'Book me the 9:00 AM slot');
      // Not the plain text path — that would lose the correlation.
      expect(source.sent, isEmpty);
    });

    test('the node is marked answered so the card disables itself', () async {
      await settle();
      bloc.add(const AiChatInteractionSubmitted(slotAnswer));
      await settle();

      expect(
        bloc.ledger.stateOf('slots_1'),
        AiUiNodeInteractionState.submitted,
      );
    });

    test('a failed turn returns the card to answerable', () async {
      await settle();
      bloc.add(const AiChatInteractionSubmitted(slotAnswer));
      await settle();

      source.emit(
        const AiChatErrorEvent(eventId: 'e', code: 'stream_interrupted'),
      );
      await settle();

      // A dropped request must never leave a control the user cannot use and
      // cannot explain.
      expect(bloc.ledger.stateOf('slots_1'), AiUiNodeInteractionState.failed);
      expect(bloc.ledger.canSubmit('slots_1'), isTrue);
    });

    test('an error after the agent replied does not blame the card', () async {
      await settle();
      bloc.add(const AiChatInteractionSubmitted(slotAnswer));
      await settle();

      source.emit(
        const AiChatMessageStartEvent(eventId: 'e', messageId: 'msg_2'),
      );
      await settle();
      source.emit(const AiChatErrorEvent(eventId: 'e', code: 'boom'));
      await settle();

      expect(
        bloc.ledger.stateOf('slots_1'),
        AiUiNodeInteractionState.submitted,
      );
    });

    test('a cancellation still travels — silence would look broken', () async {
      const declined = AiUiInteraction(
        interactionId: 'int_2',
        nodeId: 'perm_1',
        kind: AiUiInteractionKind.permissionResult,
        status: AiUiInteractionStatus.cancelled,
        value: AiUiPermissionValue(
          permission: 'camera',
          outcome: AiUiPermissionOutcome.denied,
        ),
        text: 'Declined access to the camera.',
      );

      await settle();
      bloc.add(const AiChatInteractionSubmitted(declined));
      await settle();

      expect(
        source.interactions.single.status,
        AiUiInteractionStatus.cancelled,
      );
      expect(bloc.state.messages.single.text, 'Declined access to the camera.');
    });

    test(
      'a cancellation resolves the node as cancelled, not answered',
      () async {
        // The bug this guards: the bloc used to mark every sent answer
        // `submitted`, so a declined permission card — which collapses on
        // `cancelled` — came straight back on screen underneath the agent's
        // reply to that decline.
        const declined = AiUiInteraction(
          interactionId: 'int_3',
          nodeId: 'perm_1',
          kind: AiUiInteractionKind.permissionResult,
          status: AiUiInteractionStatus.cancelled,
          value: AiUiPermissionValue(
            permission: 'camera',
            outcome: AiUiPermissionOutcome.denied,
          ),
          text: 'Declined access to the camera.',
        );

        await settle();
        bloc.add(const AiChatInteractionSubmitted(declined));
        await settle();

        expect(
          bloc.ledger.stateOf('perm_1'),
          AiUiNodeInteractionState.cancelled,
        );
      },
    );
  });

  group('a transport with no interaction contract', () {
    test('still carries the sentence, exactly as it always did', () async {
      final source = FakePlainSource();
      final bloc = AiChatBloc(
        source: source,
        validator: AiChatConfig.validator(keepUnsupportedNodes: false),
        diagnostics: const NoopAiUiDiagnosticsSink(),
      )..add(const AiChatStarted());
      addTearDown(bloc.close);

      await settle();
      bloc.add(const AiChatInteractionSubmitted(slotAnswer));
      await settle();

      expect(source.sent, ['Book me the 9:00 AM slot']);
      expect(bloc.state.messages.single.text, 'Book me the 9:00 AM slot');
    });
  });

  group('the turn body', () {
    test('a text-only turn is byte-identical to before', () {
      expect(
        AiChatTurnPayload.encode(
          conversationId: 'conv_1',
          message: 'hello',
        ),
        '{"conversation_id":"conv_1","message":"hello"}',
      );
    });

    test('an answer adds one key and keeps the sentence in message', () {
      final body = AiChatTurnPayload.encode(
        conversationId: 'conv_1',
        message: slotAnswer.text!,
        interaction: slotAnswer,
      );

      expect(body, contains('"message":"Book me the 9:00 AM slot"'));
      expect(body, contains('"interaction":'));
      expect(body, contains('"nodeId":"slots_1"'));
      expect(body, contains('"kind":"slot_selected"'));
      expect(body, contains('"messageId":"msg_1"'));
      expect(body, contains('"id":"s_0900"'));
      // No attachments key on a turn with no files — the existing rule.
      expect(body, isNot(contains('attachments')));
    });

    test('nothing credential-shaped is ever in the body', () {
      final body = AiChatTurnPayload.encode(
        conversationId: 'conv_1',
        message: slotAnswer.text!,
        interaction: slotAnswer,
      );

      expect(body.toLowerCase(), isNot(contains('token')));
      expect(body.toLowerCase(), isNot(contains('authorization')));
    });
  });

  group('the mock agent reads the answer', () {
    /// The claim under test is narrow and important: these continuations are
    /// built from the *structured* result, so they could not be produced by an
    /// agent that only received the sentence.
    String proseOf(List<AiChatEvent> script) => script
        .whereType<AiChatMessageEndEvent>()
        .map((e) => e.text ?? '')
        .join();

    test('a slot answer is confirmed by id, not by matching text', () {
      final script = interactionContinuation('msg_2', slotAnswer);
      final ui = script.whereType<AiChatUiEvent>().single;
      final blocks = ui.payload['blocks']! as List<dynamic>;
      final summary = blocks.single as Map<String, dynamic>;

      expect(proseOf(script), contains('9:00 AM'));
      expect(summary['id'], 'summary_s_0900');
    });

    test('an empty review is answered differently from a written one', () {
      const empty = AiUiInteraction(
        interactionId: 'i',
        nodeId: 'r',
        kind: AiUiInteractionKind.reviewSubmitted,
        value: AiUiTextValue(''),
      );
      const written = AiUiInteraction(
        interactionId: 'i',
        nodeId: 'r',
        kind: AiUiInteractionKind.reviewSubmitted,
        value: AiUiTextValue('This was very good'),
      );

      expect(
        proseOf(interactionContinuation('m', empty)),
        contains('without a comment'),
      );
      expect(
        proseOf(interactionContinuation('m', written)),
        contains('This was very good'),
      );
    });

    test('a saved place and a typed one lead to different replies', () {
      const saved = AiUiInteraction(
        interactionId: 'i',
        nodeId: 'l',
        kind: AiUiInteractionKind.locationSelected,
        value: AiUiLocationValue(
          id: 'home',
          name: 'Home',
          addressText: 'Marina Tower 3',
          source: AiUiLocationSource.saved,
        ),
      );
      const typed = AiUiInteraction(
        interactionId: 'i',
        nodeId: 'l',
        kind: AiUiInteractionKind.locationSelected,
        value: AiUiLocationValue(
          name: 'Al Barsha',
          source: AiUiLocationSource.typed,
        ),
      );

      expect(proseOf(interactionContinuation('m', saved)), contains('saved'));
      expect(
        proseOf(interactionContinuation('m', typed)),
        contains('Al Barsha'),
      );
    });

    test('every permission outcome gets its own continuation', () {
      final replies = <String>{};
      for (final outcome in AiUiPermissionOutcome.values) {
        final interaction = AiUiInteraction(
          interactionId: 'i',
          nodeId: 'p',
          kind: AiUiInteractionKind.permissionResult,
          status: outcome.isGranted
              ? AiUiInteractionStatus.submitted
              : AiUiInteractionStatus.cancelled,
          value: AiUiPermissionValue(
            permission: 'location',
            outcome: outcome,
          ),
        );
        replies.add(proseOf(interactionContinuation('m', interaction)));
      }

      // The case that did not exist before results: a refused permission used
      // to end in a snackbar, so the agent could only carry on as if the
      // answer had been yes.
      expect(replies, hasLength(AiUiPermissionOutcome.values.length));
    });

    test('a cancellation is acknowledged, never waited on', () {
      const cancelled = AiUiInteraction(
        interactionId: 'i',
        nodeId: 'n',
        kind: AiUiInteractionKind.slotSelected,
        status: AiUiInteractionStatus.cancelled,
        value: AiUiEmptyValue(),
      );

      expect(
        proseOf(interactionContinuation('m', cancelled)),
        contains('come back to that later'),
      );
    });

    test('every kind produces a reply — none is silently dropped', () {
      for (final kind in AiUiInteractionKind.values) {
        final script = interactionContinuation(
          'm',
          AiUiInteraction(
            interactionId: 'i',
            nodeId: 'n',
            kind: kind,
            value: const AiUiEmptyValue(),
          ),
        );
        expect(script, isNotEmpty, reason: kind.wire);
      }
    });
  });

  group('client prose', () {
    test('leaves an agent template alone', () {
      expect(withInteractionProse(slotAnswer).text, slotAnswer.text);
    });

    test('supplies words for a result the agent wrote no template for', () {
      const denied = AiUiInteraction(
        interactionId: 'i',
        nodeId: 'p',
        kind: AiUiInteractionKind.permissionResult,
        status: AiUiInteractionStatus.cancelled,
        value: AiUiPermissionValue(
          permission: 'camera',
          outcome: AiUiPermissionOutcome.denied,
        ),
      );

      // EasyLocalization is not bootstrapped — this repo's convention — so
      // `.tr()` falls back to the raw key. That the *key* appears is the
      // assertion: the bubble is never left empty.
      expect(
        withInteractionProse(denied).text,
        'ai_chat.interaction_permission_denied',
      );
    });

    test('a granted permission and a denied one read differently', () {
      AiUiInteraction result(AiUiPermissionOutcome outcome) => AiUiInteraction(
        interactionId: 'i',
        nodeId: 'p',
        kind: AiUiInteractionKind.permissionResult,
        value: AiUiPermissionValue(permission: 'camera', outcome: outcome),
      );

      expect(
        withInteractionProse(result(AiUiPermissionOutcome.granted)).text,
        isNot(withInteractionProse(result(AiUiPermissionOutcome.denied)).text),
      );
    });
  });
}
