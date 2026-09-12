import 'dart:async';

import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:core/core.dart';
import 'package:sanad_client/src/features/ai_chat/src/ai_chat_config.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/journey/ai_journey_blocks.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/journey/ai_journey_engine.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/journey/ai_journey_signal.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/journey/ai_journey_stage.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/journey/ai_journey_step.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/ai_chat_event_source.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/ai_contextual_event_source.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/ai_interactive_event_source.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/ai_multimodal_event_source.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/entities/ai_outgoing_message.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/entities/chat_context_content.dart';

/// A local stand-in for the AI agent, walking one deterministic journey.
///
/// It emits the *same wire envelopes* the live transports do — `typing`,
/// `message_start`, `text_delta`, `ui`, `message_end` — paced like a real
/// stream, so the bloc, the validator, the renderer and the protocol are all
/// exercised on their real paths. **Only the backend is simulated**: every card
/// that reaches the screen is an existing AI UI Protocol semantic node drawn by
/// the existing renderer, and there is no second component set anywhere.
///
/// The memory lives in [AiJourneyEngine], which is pure and synchronous. This
/// class owns only the wire: turning a step into events, pacing them, and
/// tearing its timers down. That split is what lets the whole journey be
/// unit-tested in microseconds without a clock.
///
/// Every continuation is chosen from the **structured** answer — the
/// interaction's `kind` and `value` — never from the sentence that travelled
/// beside it. An agent re-parsing its own prose would prove nothing about the
/// interaction contract.
class MockAiChatEventSource
    implements
        AiChatEventSource,
        AiMultimodalEventSource,
        AiInteractiveEventSource,
        AiContextualEventSource {
  /// Creates the local source.
  ///
  /// The delays exist so the streaming path is visible to a human watching; a
  /// test passes [Duration.zero] and gets the same events with no timers.
  MockAiChatEventSource({
    AiJourneyEngine? engine,
    AiUiValidator? validator,
    this.deltaDelay = const Duration(milliseconds: 45),
    this.eventDelay = const Duration(milliseconds: 220),
  }) : _engine = engine ?? AiJourneyEngine(),
       _validator =
           validator ?? AiChatConfig.validator(keepUnsupportedNodes: false);

  /// Between two `text_delta`s — roughly a fast reader's pace.
  final Duration deltaDelay;

  /// Between structural events.
  final Duration eventDelay;

  final AiJourneyEngine _engine;

  /// Applied to contextual payloads only.
  ///
  /// The conversation's own `ui` payloads are validated by `AiChatBloc`, which
  /// is where a live transport's are validated too. Contextual content does not
  /// pass through the bloc, so it is validated here instead — held to exactly
  /// the same policy rather than trusted for being local.
  final AiUiValidator _validator;

  final StreamController<AiChatEvent> _controller =
      StreamController<AiChatEvent>.broadcast();

  final StreamController<ChatContextContent?> _context =
      StreamController<ChatContextContent?>.broadcast();

  /// Every in-flight delay, so [dispose] can both cancel the timer *and*
  /// complete its future. Cancelling alone would leave an `await` in [_play]
  /// hanging forever, and a test would fail with a pending timer.
  final Map<Timer, Completer<void>> _pending = {};

  bool _disposed = false;

  @override
  Stream<AiChatEvent> get events => _controller.stream;

  @override
  Stream<ChatContextContent?> get contextualContent => _context.stream;

  /// Where the journey currently rests. For tests and diagnostics.
  AiJourneyStage get stage => _engine.stage;

  @override
  Future<void> send(String text) =>
      sendMultimodal(AiOutgoingMessage(text: text));

  @override
  Future<void> sendMultimodal(AiOutgoingMessage message) async {
    if (_disposed) return;

    // Two signals can come off one turn, and the attachments are the more
    // specific of the pair: a turn carrying photos is answering the
    // `media_request` even when the text beside them says nothing about it.
    // The engine ignores whichever does not match the stage it is waiting at,
    // so offering both is safe and neither can advance twice.
    if (message.attachments.isNotEmpty) {
      final steps = _engine.respond(
        AiJourneyAttachmentsSignal(message.attachments.length),
      );
      if (steps.isNotEmpty) {
        await _play(steps);
        return;
      }
    }

    await _play(_engine.respond(AiJourneyTextSignal(message.text)));
  }

  /// The mock agent *reads* the answer and continues from it.
  ///
  /// This is the half a scripted reply cannot prove on its own: the
  /// continuation is chosen from the interaction's kind and value, so a green
  /// test here means the result really did carry the user's choice rather than
  /// merely leaving the device.
  ///
  /// [text] is the prose the renderer posted as the user's turn. It is
  /// deliberately unread.
  @override
  Future<void> sendInteraction(
    AiUiInteraction interaction, {
    required String text,
  }) async {
    if (_disposed) return;
    await _play(_engine.respond(AiJourneyInteractionSignal(interaction)));
  }

  /// Returns the journey to its opening position.
  ///
  /// The transcript, the ledger and the staged attachments are not this
  /// object's to clear — the screen rebuilds the whole run for that. This makes
  /// sure a reused source does not remember a spent stage.
  void restart() {
    _engine.reset();
    if (!_context.isClosed) _context.add(null);
  }

  /// Turns scripted turns into the envelopes a live transport would send.
  Future<void> _play(List<AiJourneyStep> steps) async {
    // Nothing to say. Emitting an empty reply here is exactly what would turn a
    // duplicate tap into a second card, so the silence is load-bearing.
    if (steps.isEmpty) return;

    for (final step in steps) {
      if (_disposed) return;
      await _playStep(step);
    }
  }

  Future<void> _playStep(AiJourneyStep step) async {
    final messageId = 'msg_${generateUuidV4()}';

    _emit(AiChatTypingEvent(eventId: _eventId(), active: true));
    await _wait(step.thinkingDelay);
    if (_disposed) return;

    _emit(AiChatMessageStartEvent(eventId: _eventId(), messageId: messageId));
    await _wait(eventDelay);

    // Word by word, exactly as the agent streams: the bubble has to grow rather
    // than appear, or the streaming path is never exercised.
    for (final word in _chunks(step.prose)) {
      if (_disposed) return;
      _emit(
        AiChatTextDeltaEvent(
          eventId: _eventId(),
          messageId: messageId,
          delta: word,
        ),
      );
      await _wait(deltaDelay);
    }

    final ui = step.ui;
    if (ui != null) {
      if (_disposed) return;
      _emit(
        AiChatUiEvent(
          eventId: _eventId(),
          messageId: messageId,
          payload: journeyPayload(ui),
        ),
      );
      await _wait(eventDelay);
    }

    if (_disposed) return;
    _emit(
      AiChatMessageEndEvent(
        eventId: _eventId(),
        messageId: messageId,
        text: step.prose,
      ),
    );
    await _wait(eventDelay);

    _publishContext(step);
  }

  /// Publishes or withdraws the turn's contextual payload.
  ///
  /// Driven by the engine, never by a widget: the contextual surface is a
  /// second view onto what the agent is offering, so the agent is what decides
  /// whether there is anything on it.
  void _publishContext(AiJourneyStep step) {
    if (_disposed || _context.isClosed) return;

    if (step.clearsContext) {
      _context.add(null);
      return;
    }

    final context = step.context;
    if (context == null) return;

    final result = _validator.validate(journeyPayload(context.blocks));
    // A payload the validator refuses is dropped rather than rendered
    // half-built, which is the same thing that happens to a refused turn.
    if (!result.hasRenderableUi) return;

    _context.add(
      ChatContextContent(
        id: context.id,
        peekLabel: context.peekLabel,
        document: result.document!,
      ),
    );
  }

  /// Splits prose into stream-sized chunks, keeping the spaces.
  static Iterable<String> _chunks(String prose) sync* {
    final parts = prose.split(' ');
    for (var i = 0; i < parts.length; i++) {
      yield i == parts.length - 1 ? parts[i] : '${parts[i]} ';
    }
  }

  static String _eventId() => 'evt_${generateUuidV4()}';

  void _emit(AiChatEvent event) {
    if (_disposed || _controller.isClosed) return;
    _controller.add(event);
  }

  Future<void> _wait(Duration duration) {
    if (duration == Duration.zero) return Future<void>.value();

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
      // Resume the awaiting _play so it can observe _disposed and stop, rather
      // than leaving the future dangling.
      if (!entry.value.isCompleted) entry.value.complete();
    }
    _pending.clear();
    await _controller.close();
    await _context.close();
  }
}
