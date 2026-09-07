import 'dart:async';

import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:core/core.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/mock_scenarios.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/mocks/multimodal_mock_scenarios.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/ai_chat_event_source.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/ai_multimodal_event_source.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/entities/ai_outgoing_message.dart';

/// A local stand-in for the AI agent.
///
/// It emits the *same wire envelopes* a socket would, paced like a real
/// stream, so the bloc, renderer and protocol are all exercised on their real
/// paths. Swapping this for a WebSocket source is a new class implementing
/// [AiChatEventSource] — nothing above it changes.
class MockAiChatEventSource
    implements AiChatEventSource, AiMultimodalEventSource {
  /// Creates a scripted source. The delays exist so the streaming path is
  /// visible to a human watching the prototype.
  MockAiChatEventSource({
    this.deltaDelay = const Duration(milliseconds: 45),
    this.eventDelay = const Duration(milliseconds: 220),
    this.thinkingDelay = const Duration(milliseconds: 400),
  });

  /// Between two `text_delta`s — roughly a fast reader's pace.
  final Duration deltaDelay;

  /// Between structural events.
  final Duration eventDelay;

  /// Before the reply starts, so the typing indicator is visible.
  final Duration thinkingDelay;

  final StreamController<AiChatEvent> _controller =
      StreamController<AiChatEvent>.broadcast();

  /// When set, [send] always replays this scenario instead of matching on the
  /// message text. Drives the dev scenario menu.
  String? forcedScenarioId;

  /// Every in-flight delay, so [dispose] can both cancel the timer *and*
  /// complete its future. Cancelling alone would leave an `await` in [_replay]
  /// hanging forever, and a test would fail with a pending timer.
  final Map<Timer, Completer<void>> _pending = {};

  bool _disposed = false;

  @override
  Stream<AiChatEvent> get events => _controller.stream;

  @override
  Future<void> send(String text) =>
      sendMultimodal(AiOutgoingMessage(text: text));

  @override
  Future<void> sendMultimodal(AiOutgoingMessage message) async {
    if (_disposed) return;

    final messageId = 'msg_${generateUuidV4()}';

    // The dev scenario picker still wins, even for a turn with attachments —
    // that is how the deliberately-broken payloads stay reachable.
    final forced = forcedScenarioId;
    final script = forced == null
        ? MultimodalMockScenarios.reply(messageId, message)
        : mockScenarios
              .firstWhere(
                (s) => s.id == forced,
                orElse: () => mockScenarios.first,
              )
              .build(messageId);

    _emit(
      AiChatTypingEvent(eventId: 'evt_${generateUuidV4()}', active: true),
    );

    await _wait(thinkingDelay);
    await _replay(script);
  }

  Future<void> _replay(List<AiChatEvent> script) async {
    for (final event in script) {
      if (_disposed) return;
      _emit(event);
      await _wait(
        event is AiChatTextDeltaEvent ? deltaDelay : eventDelay,
      );
    }
  }

  void _emit(AiChatEvent event) {
    if (_disposed || _controller.isClosed) return;
    _controller.add(event);
  }

  Future<void> _wait(Duration duration) {
    final completer = Completer<void>();
    late final Timer timer;
    timer = Timer(duration, () {
      _pending.remove(timer);
      if (!completer.isCompleted) completer.complete();
    });
    _pending[timer] = completer;
    return completer.future;
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    for (final entry in _pending.entries) {
      entry.key.cancel();
      // Resume the awaiting _replay so it can observe _disposed and stop,
      // rather than leaving the future dangling.
      if (!entry.value.isCompleted) entry.value.complete();
    }
    _pending.clear();
    await _controller.close();
  }
}
