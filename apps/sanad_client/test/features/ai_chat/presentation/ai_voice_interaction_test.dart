import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/ai_ui_renderer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_client/src/features/ai_chat/src/ai_chat_config.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/platform/voice/mock_voice_scenarios.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/entities/ai_voice_event.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/enums/ai_voice_session_status.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_permission_gateway.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/actions/ai_voice_interaction_sink.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/ai_voice_session_bloc.dart';

import '../support/voice_fakes.dart';

/// A gateway that always says yes, so the bloc's own permission gate is not
/// the subject here.
class AllowingGateway implements AiPermissionGateway {
  @override
  Future<AiPermissionOutcome> ensureCamera() async =>
      AiPermissionOutcome.granted;
  @override
  Future<AiPermissionOutcome> ensureGallery() async =>
      AiPermissionOutcome.granted;
  @override
  Future<AiPermissionOutcome> ensureMicrophone() async =>
      AiPermissionOutcome.granted;
  @override
  Future<AiPermissionOutcome> ensureSpeechRecognition() async =>
      AiPermissionOutcome.granted;
  @override
  Future<AiPermissionOutcome> ensureLocation() async =>
      AiPermissionOutcome.granted;
  @override
  Future<AiPermissionOutcome> ensureNotifications() async =>
      AiPermissionOutcome.granted;
  @override
  Future<void> openSettings() async {}
}

void main() {
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  const answer = AiUiInteraction(
    interactionId: 'int_1',
    nodeId: 'voice_slots',
    nodeType: AiUiNodeType.timeSlots,
    kind: AiUiInteractionKind.slotSelected,
    value: AiUiSelectionValue(id: 's_0900', label: '9:00 AM'),
    text: 'Book me the 9:00 AM slot',
  );

  group('the voice bloc', () {
    late FakeVoiceSession session;
    late AiVoiceSessionBloc bloc;

    setUp(() {
      session = FakeVoiceSession();
      bloc = AiVoiceSessionBloc(
        session: session,
        permissions: AllowingGateway(),
        validator: AiChatConfig.validator(keepUnsupportedNodes: false),
      );
    });

    tearDown(() async => bloc.close());

    test('a UI request is validated once, on arrival', () async {
      await session.emitEvent(
        const AiVoiceUiRequested(MockVoiceScenarios.timeSlots),
      );
      await settle();

      // A validated document, never raw JSON — so no `build()` pays for
      // decoding or can be surprised by a malformed payload.
      expect(bloc.state.hasDocument, isTrue);
      expect(bloc.state.document!.blocks.single, isA<AiUiTimeSlotsNode>());
    });

    test('a payload that validates to nothing leaves no empty panel', () async {
      await session.emitEvent(
        const AiVoiceUiRequested({
          'schemaVersion': 1,
          'blocks': <Map<String, dynamic>>[],
        }),
      );
      await settle();

      expect(bloc.state.hasDocument, isFalse);
    });

    test('a malformed payload does not throw or strand the session', () async {
      await session.emitEvent(
        const AiVoiceUiRequested({'schemaVersion': 'one', 'blocks': 'nope'}),
      );
      await settle();

      expect(bloc.state.document, isNull);
    });

    test('answering hands the interaction to the session', () async {
      await session.emitEvent(
        const AiVoiceUiRequested(MockVoiceScenarios.timeSlots),
      );
      await settle();

      bloc.add(const AiVoiceSessionInteractionSubmitted(answer));
      await settle();

      expect(session.interactions.single, answer);
      expect(
        bloc.ledger.stateOf('voice_slots'),
        AiUiNodeInteractionState.submitted,
      );
    });

    test('the panel comes down when the card resolves', () async {
      await session.emitEvent(
        const AiVoiceUiRequested(MockVoiceScenarios.timeSlots),
      );
      await settle();
      await session.emitEvent(const AiVoiceUiResolved('voice_slots'));
      await settle();

      expect(bloc.state.hasDocument, isFalse);
    });

    test('a session ending clears the card and frees the node', () async {
      await session.emitEvent(
        const AiVoiceUiRequested(MockVoiceScenarios.timeSlots),
      );
      await settle();
      // Nothing will ever resolve a claim whose session has gone.
      bloc.ledger.beginSubmission('voice_slots');
      await session.emitEvent(const AiVoiceUiResolved('voice_slots'));
      await settle();

      expect(
        bloc.ledger.stateOf('voice_slots'),
        AiUiNodeInteractionState.active,
      );
    });

    test('a terminal status takes the card down too', () async {
      await session.emitEvent(
        const AiVoiceUiRequested(MockVoiceScenarios.timeSlots),
      );
      await settle();
      await session.emitStatus(AiVoiceSessionStatus.ended);

      expect(bloc.state.hasDocument, isFalse);
    });

    test('awaiting an answer is reflected in state', () async {
      await session.emitStatus(AiVoiceSessionStatus.awaitingInteraction);

      expect(bloc.state.status, AiVoiceSessionStatus.awaitingInteraction);
      expect(bloc.state.status.isActive, isTrue);
      // The answer is coming from a finger, not a voice.
      expect(bloc.state.status.capturesAudio, isFalse);
    });

    test('level readings still emit no state', () async {
      final states = <AiVoiceSessionState>[];
      final sub = bloc.stream.listen(states.add);

      await session.emitLevel(0.4);
      await session.emitLevel(0.8);

      expect(states, isEmpty);
      expect(bloc.level.value, 0.8);
      await sub.cancel();
    });

    test('closing twice is safe with a card on screen', () async {
      await session.emitEvent(
        const AiVoiceUiRequested(MockVoiceScenarios.timeSlots),
      );
      await settle();

      await bloc.close();
      await expectLater(bloc.close(), completes);
    });
  });

  group('the sink', () {
    test('fills in prose the agent wrote no template for', () async {
      final session = FakeVoiceSession();
      final bloc = AiVoiceSessionBloc(
        session: session,
        permissions: AllowingGateway(),
      );
      addTearDown(bloc.close);

      AiVoiceInteractionSink(bloc).submit(
        const AiUiInteraction(
          interactionId: 'i',
          nodeId: 'voice_permission',
          kind: AiUiInteractionKind.permissionResult,
          status: AiUiInteractionStatus.cancelled,
          value: AiUiPermissionValue(
            permission: 'location',
            outcome: AiUiPermissionOutcome.denied,
          ),
        ),
      );
      await settle();

      expect(session.interactions.single.text, isNotNull);
    });
  });

  group('the scripted beats', () {
    test('three turns ask, the rest speak', () {
      expect(MockVoiceScenarios.standard(1), isNotNull);
      expect(MockVoiceScenarios.standard(2), isNotNull);
      expect(MockVoiceScenarios.standard(3), isNotNull);
      expect(MockVoiceScenarios.standard(4), isNull);
    });

    test('the echo-only script asks nothing', () {
      expect(MockVoiceScenarios.none(1), isNull);
    });

    test('every scripted payload survives the real validator', () {
      // A scripted card that the app's own validator would drop is a demo of
      // nothing. Wired to the same validator the screen uses.
      final validator = AiChatConfig.validator(keepUnsupportedNodes: false);

      for (final payload in [
        MockVoiceScenarios.timeSlots,
        MockVoiceScenarios.locationPicker,
        MockVoiceScenarios.locationPermission,
      ]) {
        expect(
          validator.validate(payload).hasRenderableUi,
          isTrue,
          reason: '$payload',
        );
      }
    });
  });

  // Regression for A-08: once a card was confirmed it vanished and the
  // assistant acknowledged in audio only, so a user who missed the audio had
  // no record at all of what they had just booked.
  group('the answered line', () {
    late FakeVoiceSession session;
    late AiVoiceSessionBloc bloc;

    setUp(() {
      session = FakeVoiceSession();
      bloc = AiVoiceSessionBloc(
        session: session,
        permissions: AllowingGateway(),
        validator: AiChatConfig.validator(keepUnsupportedNodes: false),
      );
    });

    tearDown(() async => bloc.close());

    test('keeps the submitted answer on screen', () async {
      bloc.add(const AiVoiceSessionInteractionSubmitted(answer));
      await settle();

      expect(bloc.state.lastAnswer, 'Book me the 9:00 AM slot');
    });

    test('a cancelled answer leaves no line', () async {
      // Nothing was chosen, and "you chose nothing" is noise.
      bloc.add(const AiVoiceSessionInteractionSubmitted(answer));
      await settle();

      bloc.add(
        const AiVoiceSessionInteractionSubmitted(
          AiUiInteraction(
            interactionId: 'int_2',
            nodeId: 'voice_slots',
            nodeType: AiUiNodeType.timeSlots,
            kind: AiUiInteractionKind.slotSelected,
            status: AiUiInteractionStatus.cancelled,
            value: AiUiSelectionValue(id: 's_0900', label: '9:00 AM'),
            text: 'Never mind',
          ),
        ),
      );
      await settle();

      expect(bloc.state.lastAnswer, isNull);
    });

    test('a new question clears the previous answer', () async {
      bloc.add(const AiVoiceSessionInteractionSubmitted(answer));
      await settle();
      expect(bloc.state.lastAnswer, isNotNull);

      await session.emitEvent(
        const AiVoiceUiRequested(MockVoiceScenarios.timeSlots),
      );
      await settle();

      expect(bloc.state.lastAnswer, isNull);
    });
  });
}
