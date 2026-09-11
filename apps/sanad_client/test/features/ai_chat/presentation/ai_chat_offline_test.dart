import 'dart:async';

import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/ai_ui_renderer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network/network.dart';
import 'package:sanad_client/src/features/ai_chat/src/ai_chat_config.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/ai_chat_event_source.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/ai_chat_message.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/ai_chat_bloc.dart';

/// The offline half of the message lifecycle, and the line between it and a
/// send that failed.
///
/// The distinction is the whole subject: **queued** means the turn never left
/// the device and will when it can, **failed** means it left and did not
/// arrive. Collapsing them either way produces a lie the user acts on — a
/// Retry that cannot work, or a message shown as on its way while the radio
/// is off.
class _FakeSource implements AiChatEventSource {
  final StreamController<AiChatEvent> _controller =
      StreamController<AiChatEvent>.broadcast();
  final List<String> sent = [];

  @override
  Stream<AiChatEvent> get events => _controller.stream;

  @override
  Future<void> send(String text) async => sent.add(text);

  void emit(AiChatEvent event) => _controller.add(event);

  @override
  Future<void> dispose() async => _controller.close();
}

/// A connectivity signal the test drives directly, so a flip is an explicit
/// step rather than a timer.
class _FakeConnectivity implements ConnectivityService {
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  bool connected = true;

  /// How many times the bloc asked. Proves a retry re-checks rather than
  /// trusting the flag it already holds.
  int checks = 0;

  @override
  Future<bool> isConnected() async {
    checks++;
    return connected;
  }

  @override
  Stream<bool> onConnectionChanged() => _controller.stream;

  void goOnline({required bool online}) {
    connected = online;
    _controller.add(online);
  }

  Future<void> dispose() => _controller.close();
}

void main() {
  late _FakeSource source;
  late _FakeConnectivity connectivity;
  late AiChatBloc bloc;

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  AiChatBloc build() => AiChatBloc(
    source: source,
    validator: AiChatConfig.validator(keepUnsupportedNodes: false),
    diagnostics: RecordingAiUiDiagnosticsSink(),
    connectivity: connectivity,
  )..add(const AiChatStarted());

  setUp(() {
    source = _FakeSource();
    connectivity = _FakeConnectivity();
  });

  tearDown(() async {
    await bloc.close();
    await connectivity.dispose();
  });

  group('opening the chat', () {
    test('reads the current connection rather than assuming online', () async {
      // The stream reports only *changes*, so a chat opened with the radio
      // already off would otherwise queue nothing and fail every send.
      connectivity.connected = false;
      bloc = build();
      await settle();

      expect(bloc.state.isOffline, isTrue);
    });

    test('a chat opened online is not offline', () async {
      bloc = build();
      await settle();

      expect(bloc.state.isOffline, isFalse);
    });
  });

  group('queueing while offline', () {
    setUp(() async {
      connectivity.connected = false;
      bloc = build();
      await settle();
    });

    test('a turn is held, not handed to the transport', () async {
      bloc.add(const AiChatMessageSubmitted('I need AC repairing today'));
      await settle();

      final message = bloc.state.messages.single;
      expect(message.status, AiChatMessageStatus.queued);
      expect(message.text, 'I need AC repairing today');
      // Never attempted: this is what separates queued from failed.
      expect(source.sent, isEmpty);
    });

    test('a queued turn is not reported as failed', () async {
      bloc.add(const AiChatMessageSubmitted('hello'));
      await settle();

      expect(bloc.state.messages.single.status.isFailed, isFalse);
      expect(bloc.state.messages.single.status.isSending, isFalse);
      expect(bloc.state.hasUndeliveredMessage, isFalse);
    });

    test('it is still retryable, because Retry means "try now"', () async {
      bloc.add(const AiChatMessageSubmitted('hello'));
      await settle();

      expect(bloc.state.messages.single.status.isRetryable, isTrue);
    });

    test('retrying while still offline keeps it queued', () async {
      bloc.add(const AiChatMessageSubmitted('hello'));
      await settle();

      final before = connectivity.checks;
      bloc.add(AiChatMessageRetryRequested(bloc.state.messages.single.id));
      await settle();

      // Re-checked rather than assumed, and still held rather than failed.
      expect(connectivity.checks, greaterThan(before));
      expect(bloc.state.messages.single.status, AiChatMessageStatus.queued);
      expect(source.sent, isEmpty);
    });

    test('retrying once signal is back sends it', () async {
      bloc.add(const AiChatMessageSubmitted('hello'));
      await settle();

      // Signal returns without the stream having fired — walking back into
      // coverage is exactly this case, and a stale flag would refuse the send.
      connectivity.connected = true;
      bloc.add(AiChatMessageRetryRequested(bloc.state.messages.single.id));
      await settle();

      expect(bloc.state.messages.single.status, AiChatMessageStatus.sending);
      expect(bloc.state.isOffline, isFalse);
      expect(source.sent, ['hello']);
    });

    test('an answer to a card is refused rather than queued', () async {
      // A queued *message* is still the user's own words whenever it lands; a
      // queued *answer* would be a decision about a card that may no longer be
      // the live question. The card comes back instead.
      const interaction = AiUiInteraction(
        interactionId: 'int_1',
        nodeId: 'rn_1',
        kind: AiUiInteractionKind.confirmationResolved,
        value: AiUiConfirmationValue(confirmed: true),
        text: 'Start a new conversation',
      );
      bloc.ledger.beginSubmission('rn_1');

      bloc.add(const AiChatInteractionSubmitted(interaction));
      await settle();

      expect(bloc.ledger.stateOf('rn_1'), AiUiNodeInteractionState.failed);
      expect(bloc.ledger.canSubmit('rn_1'), isTrue);
      expect(bloc.state.messages, isEmpty);
      expect(source.sent, isEmpty);
      expect(bloc.state.failure, isNotNull);
    });
  });

  group('flushing when the connection comes back', () {
    setUp(() async {
      connectivity.connected = false;
      bloc = build();
      await settle();
    });

    test('queued turns are sent in the order they were written', () async {
      bloc
        ..add(const AiChatMessageSubmitted('first'))
        ..add(const AiChatMessageSubmitted('second'));
      await settle();
      expect(source.sent, isEmpty);

      connectivity.goOnline(online: true);
      await settle();

      expect(source.sent, ['first', 'second']);
      expect(bloc.state.queuedMessages, isEmpty);
      expect(bloc.state.isOffline, isFalse);
    });

    test(
      'a flushed turn moves to sending, not straight to delivered',
      () async {
        bloc.add(const AiChatMessageSubmitted('hello'));
        await settle();
        connectivity.goOnline(online: true);
        await settle();

        // Handed over is not the same as arrived: only the agent replying makes
        // it complete, exactly as for a turn sent while online.
        expect(bloc.state.messages.single.status, AiChatMessageStatus.sending);

        source.emit(
          const AiChatMessageStartEvent(eventId: 'e0', messageId: 'msg_1'),
        );
        await settle();

        expect(bloc.state.messages.first.status, AiChatMessageStatus.complete);
      },
    );

    test(
      'going offline again does not touch a turn already in flight',
      () async {
        connectivity.goOnline(online: true);
        await settle();
        bloc.add(const AiChatMessageSubmitted('hello'));
        await settle();

        connectivity.goOnline(online: false);
        await settle();

        // It may still land — nothing here can know it will not, so claiming it
        // failed would be inventing an outcome.
        expect(bloc.state.messages.single.status, AiChatMessageStatus.sending);
        expect(bloc.state.isOffline, isTrue);
      },
    );

    test('a repeated online signal does not send twice', () async {
      bloc.add(const AiChatMessageSubmitted('hello'));
      await settle();

      connectivity
        ..goOnline(online: true)
        ..goOnline(online: true);
      await settle();

      expect(source.sent, ['hello']);
    });
  });

  group('offline and failed are different states', () {
    test('a failed turn is failed, a held one is queued', () async {
      bloc = build();
      await settle();

      bloc.add(const AiChatMessageSubmitted('online turn'));
      await settle();
      source.emit(
        const AiChatErrorEvent(eventId: 'e1', code: 'connection_failed'),
      );
      await settle();

      connectivity.goOnline(online: false);
      await settle();
      bloc.add(const AiChatMessageSubmitted('offline turn'));
      await settle();

      expect(
        bloc.state.messages.map((m) => m.status),
        [AiChatMessageStatus.failed, AiChatMessageStatus.queued],
      );
      // Only the attempted one counts as undelivered, which is what keeps the
      // send-failure banner from appearing for a turn that was never sent.
      expect(bloc.state.hasUndeliveredMessage, isTrue);
      expect(bloc.state.queuedMessages, hasLength(1));
    });

    test('a flush never resurrects a failed turn', () async {
      connectivity.connected = false;
      bloc = build();
      await settle();

      bloc.add(const AiChatMessageSubmitted('held'));
      await settle();
      connectivity.goOnline(online: true);
      await settle();
      source.emit(
        const AiChatErrorEvent(eventId: 'e1', code: 'connection_failed'),
      );
      await settle();
      expect(bloc.state.messages.single.status, AiChatMessageStatus.failed);

      // A second online signal must not re-send it: it is no longer queued,
      // and only an explicit Retry may try again.
      connectivity
        ..goOnline(online: false)
        ..goOnline(online: true);
      await settle();

      expect(source.sent, ['held']);
      expect(bloc.state.messages.single.status, AiChatMessageStatus.failed);
    });
  });
}
