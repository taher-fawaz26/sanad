import 'dart:async';

import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/ai_ui_renderer.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:network/network.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/ai_chat_event_source.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/ai_chat_message.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/ai_interactive_event_source.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/ai_multimodal_event_source.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/entities/ai_chat_attachment.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/entities/ai_outgoing_message.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/active_stream_controller.dart';

part 'ai_chat_bloc_event.dart';
part 'ai_chat_state.dart';

/// Owns the conversation.
///
/// Two deliberate design points:
///
/// 1. **Parse once, at ingestion.** A `ui` event is validated here and stored
///    as an `AiUiDocument`. No widget ever sees raw JSON, so no `build()` can
///    pay for decoding or be surprised by a malformed payload.
///
/// 2. **Token deltas never reach the state.** `text_delta` writes to
///    [activeStream] and emits nothing, so only the active bubble rebuilds.
///    The bloc emits a list-level state only when a message is added,
///    completed, or fails. See [ActiveStreamController].
class AiChatBloc extends Bloc<AiChatBlocEvent, AiChatState> {
  /// [activeStream] is injectable so a test can observe token-level updates
  /// without reaching into the bloc.
  AiChatBloc({
    required AiChatEventSource source,
    required AiUiValidator validator,
    required AiUiDiagnosticsSink diagnostics,
    ActiveStreamController? activeStream,
    AiUiInteractionLedger? ledger,
    ConnectivityService? connectivity,
  }) : _source = source,
       _validator = validator,
       _diagnostics = diagnostics,
       _connectivity = connectivity,
       activeStream = activeStream ?? ActiveStreamController(),
       ledger = ledger ?? AiUiInteractionLedger(),
       super(const AiChatState()) {
    on<AiChatStarted>(_onStarted);
    on<AiChatMessageSubmitted>(_onSubmitted, transformer: droppable());
    // Sequential, not droppable: a flush has to run after whatever send is
    // already leaving, and dropping a regained-connection event would leave
    // the queue stuck until the next flip.
    on<AiChatConnectivityChanged>(_onConnectivityChanged);
    // The same double-tap guard a typed turn gets. The ledger already refuses
    // a second answer to the same node; this refuses a second answer to two
    // different nodes while the first is still leaving.
    on<AiChatInteractionSubmitted>(
      _onInteraction,
      transformer: droppable(),
    );
    // Droppable for the same reason a submit is: a failed bubble invites
    // repeated taps, and each one must not become another turn on the wire.
    on<AiChatMessageRetryRequested>(_onRetry, transformer: droppable());
    on<AiChatTransportEventReceived>(_onTransportEvent);
  }

  final AiChatEventSource _source;
  final AiUiValidator _validator;
  final AiUiDiagnosticsSink _diagnostics;

  /// Tells the bloc whether a turn can leave the device at all.
  ///
  /// The shared `network` abstraction rather than `connectivity_plus` or the
  /// app-wide `ConnectivityController`: this bloc needs a stream and a
  /// one-shot check, both of which the service already gives it, and neither
  /// a plugin type nor a `ChangeNotifier` belongs in a bloc's constructor.
  ///
  /// Nullable so a test — and the scripted mock transport — can run without
  /// one, in which case the chat behaves exactly as it did before offline
  /// queueing existed: every turn is attempted immediately.
  final ConnectivityService? _connectivity;

  /// Exposed so the streaming bubble can listen directly, bypassing the bloc's
  /// state entirely for per-token updates.
  final ActiveStreamController activeStream;

  /// The answer lifecycle of every semantic node in this conversation.
  ///
  /// Owned here, and for the same reason [activeStream] is: it must outlive
  /// any single widget. A card scrolled out of the list and back must still
  /// know it was answered, and a send that fails must re-enable the card it
  /// came from — neither is expressible in widget state, and putting it in
  /// [AiChatState] would rebuild the whole conversation on every selection.
  final AiUiInteractionLedger ledger;

  StreamSubscription<AiChatEvent>? _subscription;
  StreamSubscription<bool>? _connectivitySubscription;

  /// The node whose answer is in flight, if any.
  ///
  /// Needed because the transports do not throw on a failed turn — they emit
  /// an `error` frame — so "did my answer arrive?" is only knowable when that
  /// frame lands. Holding the id here is what lets the failure re-enable the
  /// right card instead of leaving it disabled forever.
  String? _pendingInteractionNodeId;

  /// The user turn that has been handed to the transport but is not yet known
  /// to have arrived (A-03).
  ///
  /// Same reasoning as [_pendingInteractionNodeId], for the other half of the
  /// conversation: a send is fire-and-forget, so "did my message arrive?" is
  /// only answerable when the agent either starts replying or reports an
  /// error. Holding the id is what lets that answer reach the right bubble
  /// instead of leaving every turn looking delivered.
  String? _pendingUserMessageId;

  bool _closed = false;

  Future<void> _onStarted(
    AiChatStarted event,
    Emitter<AiChatState> emit,
  ) async {
    await _subscription?.cancel();
    _subscription = _source.events.listen(
      (transportEvent) => add(AiChatTransportEventReceived(transportEvent)),
    );

    final connectivity = _connectivity;
    var offline = false;
    if (connectivity != null) {
      await _connectivitySubscription?.cancel();
      _connectivitySubscription = connectivity.onConnectionChanged().listen(
        (online) => add(AiChatConnectivityChanged(isOnline: online)),
      );
      // The stream only reports *changes*, so the current state has to be read
      // once — otherwise a chat opened with the radio already off would queue
      // nothing and fail every send instead.
      offline = !await connectivity.isConnected();
    }

    emit(state.copyWith(status: RequestStatus.success, isOffline: offline));
  }

  Future<void> _onSubmitted(
    AiChatMessageSubmitted event,
    Emitter<AiChatState> emit,
  ) async {
    final text = event.text.trim();
    final attachments = event.attachments;
    // An attachment-only turn is legitimate — a photo with no caption, a voice
    // note on its own — so empty text alone no longer means "nothing to send".
    if (text.isEmpty && attachments.isEmpty) return;

    final id = 'user_${generateUuidV4()}';
    // Offline the turn is *held*, not attempted: it never reaches the
    // transport, so it is neither on its way nor failed, and it keeps its
    // place in the transcript so the user can see what will go out.
    final queued = state.isOffline;
    if (!queued) _pendingUserMessageId = id;

    emit(
      state.copyWith(
        messages: [
          ...state.messages,
          AiChatMessage.user(
            id: id,
            text: text,
            attachments: attachments,
            createdAt: DateTime.now(),
            status: queued
                ? AiChatMessageStatus.queued
                : AiChatMessageStatus.sending,
          ),
        ],
      ),
    );

    if (queued) return;
    await _deliver(text: text, attachments: attachments);
  }

  /// Connectivity flipped.
  ///
  /// Going offline only records the fact — nothing in flight is touched,
  /// because a turn already handed over may still land. Coming back online
  /// flushes whatever was held, oldest first, so the conversation reads in the
  /// order the user wrote it.
  Future<void> _onConnectivityChanged(
    AiChatConnectivityChanged event,
    Emitter<AiChatState> emit,
  ) async {
    final online = event.isOnline;
    if (state.isOffline == !online) return;

    emit(state.copyWith(isOffline: !online));
    if (!online) return;

    for (final queued in state.queuedMessages.toList()) {
      // Re-read from state each time: a queued turn may have been retried by
      // hand between iterations, and sending it twice is exactly what the
      // status check prevents.
      final current = state.messages
          .where((m) => m.id == queued.id)
          .firstOrNull;
      if (current == null || !current.status.isQueued) continue;

      _pendingUserMessageId = current.id;
      emit(
        state.copyWith(
          messages: _replace(
            current.id,
            (m) => m.copyWith(status: AiChatMessageStatus.sending),
          ),
        ),
      );
      await _deliver(
        text: current.text,
        attachments: current.attachments,
      );
    }
  }

  /// Hands one turn to whichever transport contract this source speaks.
  ///
  /// Shared by the first attempt and by [_onRetry] so a retry cannot drift
  /// into a second, subtly different send path.
  Future<void> _deliver({
    required String text,
    required List<AiChatAttachment> attachments,
  }) async {
    final source = _source;
    // A variable pattern rather than `is`: Dart forms no intersection type for
    // two unrelated interfaces, so a plain `is` would not promote here.
    if (source case final AiMultimodalEventSource multimodal) {
      await multimodal.sendMultimodal(
        AiOutgoingMessage(text: text, attachments: attachments),
      );
      return;
    }

    // A transport with no multimodal contract still carries the text. The
    // attachments remain visible in the user's own bubble, which is the
    // honest degradation: nothing is invented on a wire that cannot express
    // it. See `AiMultimodalEventSource` for why this is a capability test
    // rather than a method on the base interface.
    await source.send(text);
  }

  /// Sends a failed turn again (A-03).
  ///
  /// Re-sends the *same* bubble rather than appending a new one: the user
  /// asked for that message to arrive, not for a second copy of it. The
  /// message returns to [AiChatMessageStatus.sending] and becomes the pending
  /// turn again, so the next `message_start` or `error` resolves it exactly as
  /// it would have the first time.
  Future<void> _onRetry(
    AiChatMessageRetryRequested event,
    Emitter<AiChatState> emit,
  ) async {
    final message = state.messages
        .where((m) => m.id == event.messageId)
        .firstOrNull;
    // Only a failed or queued turn can be retried. Anything else — a delivered
    // message, an id that no longer exists — is a stale tap on a rebuilt list.
    if (message == null || !message.status.isRetryable) return;

    // Retrying is also a "try now": re-check the radio rather than trusting a
    // flag that may predate the user walking back into signal. A device still
    // offline leaves the turn queued instead of failing it a second time.
    final connectivity = _connectivity;
    if (connectivity != null && !await connectivity.isConnected()) {
      emit(
        state.copyWith(
          isOffline: true,
          messages: _replace(
            message.id,
            (m) => m.copyWith(status: AiChatMessageStatus.queued),
          ),
        ),
      );
      return;
    }

    _pendingUserMessageId = message.id;
    emit(
      state.copyWith(
        isOffline: false,
        messages: _replace(
          message.id,
          (m) => m.copyWith(status: AiChatMessageStatus.sending),
        ),
      ),
    );

    await _deliver(text: message.text, attachments: message.attachments);
  }

  /// Turns one answer into a user turn and sends it.
  ///
  /// The user's interaction becomes a real bubble — "Book me the 9:00 AM
  /// slot", "camera: granted" — because a conversation where half the turns
  /// are invisible reads as if the assistant is talking to itself. It is the
  /// same `AiChatMessage.user` a typed turn produces, so nothing downstream
  /// has a second shape to handle.
  Future<void> _onInteraction(
    AiChatInteractionSubmitted event,
    Emitter<AiChatState> emit,
  ) async {
    final interaction = event.interaction;
    final text = interaction.text ?? '';

    // Offline, an answer is refused rather than queued. A queued *message* is
    // still the user's own words whenever it lands; a queued *answer* would be
    // a decision about a card that may no longer be the live question by then,
    // and the ledger would have to hold a claim across an unbounded wait. So
    // the card comes back instead, and the offline banner already says why.
    if (state.isOffline) {
      ledger.markFailed(interaction.nodeId);
      emit(
        state.copyWith(
          failure: AiChatFailure(
            id: 'failure_${generateUuidV4()}',
            message: 'ai_chat.offline_action_blocked',
          ),
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        messages: [
          ...state.messages,
          AiChatMessage.user(
            id: _pendingUserMessageId = 'user_${generateUuidV4()}',
            text: text,
            interaction: interaction,
            createdAt: DateTime.now(),
          ),
        ],
      ),
    );

    final source = _source;
    // A variable pattern rather than `is`, for the same reason as the
    // multimodal check below it: Dart forms no intersection type for two
    // unrelated interfaces.
    _pendingInteractionNodeId = interaction.nodeId;

    if (source case final AiInteractiveEventSource interactive) {
      await interactive.sendInteraction(interaction, text: text);
      // Resolved from the status the answer carried, not assumed to be
      // `submitted`: a declined permission that resolved as answered would
      // leave the card it came from on screen underneath the agent's reply
      // to that decline.
      ledger.resolve(interaction.nodeId, interaction.status);
      return;
    }

    // A transport that cannot express a structured result still carries the
    // sentence — which is exactly what a tapped card sent before results
    // existed. Nothing is invented on a wire that cannot express it.
    if (text.isNotEmpty) await source.send(text);
    ledger.resolve(interaction.nodeId, interaction.status);
  }

  void _onTransportEvent(
    AiChatTransportEventReceived event,
    Emitter<AiChatState> emit,
  ) {
    switch (event.event) {
      case AiChatMessageStartEvent(:final messageId?):
        // The agent is answering, so whatever answer was in flight arrived.
        _pendingInteractionNodeId = null;
        activeStream.start(messageId);
        // …and so did the user turn that prompted it. This is the only
        // positive delivery signal the transports give: `send` is
        // fire-and-forget, so a reply starting is what proves the turn landed.
        final delivered = _markPendingUserMessage(
          AiChatMessageStatus.complete,
        );
        emit(
          state.copyWith(
            isTyping: false,
            messages: [
              ...delivered,
              AiChatMessage(
                id: messageId,
                role: AiChatRole.assistant,
                status: AiChatMessageStatus.streaming,
                createdAt: DateTime.now(),
              ),
            ],
          ),
        );

      case AiChatTextDeltaEvent(:final delta, :final messageId?):
        // The hot path. No emit, by design — see the class doc.
        if (activeStream.isActive(messageId)) activeStream.append(delta);

      case AiChatMessageEndEvent(:final messageId?, :final text):
        final accumulated = activeStream.isActive(messageId)
            ? activeStream.finish()
            : '';
        emit(
          state.copyWith(
            messages: _replace(
              messageId,
              (message) => message.copyWith(
                // `message_end.text` is authoritative: a dropped delta cannot
                // leave a permanently wrong bubble.
                text: text ?? accumulated,
                status: AiChatMessageStatus.complete,
              ),
            ),
          ),
        );

      case AiChatUiEvent(:final messageId?, :final payload):
        emit(state.copyWith(messages: _attachUi(messageId, payload)));

      case AiChatTypingEvent(:final active):
        emit(state.copyWith(isTyping: active));

      // A message-scoped event with no messageId cannot be attributed to a
      // bubble. The codec already rejects those, so this only guards against a
      // future event shape.
      case AiChatMessageStartEvent() ||
          AiChatTextDeltaEvent() ||
          AiChatMessageEndEvent() ||
          AiChatUiEvent():
        break;

      case AiChatErrorEvent(:final code, :final message):
        _diagnostics.report(
          AiUiDiagnostic(
            code: AiUiDiagnosticCode.malformedPayload,
            path: r'$',
            detail: 'agent error: $code',
          ),
        );
        // An answer that was in flight did not land. The card comes back
        // rather than staying disabled — a dropped request must never leave
        // the user looking at a control they cannot use and cannot explain.
        final strandedNode = _pendingInteractionNodeId;
        if (strandedNode != null) {
          ledger.markFailed(strandedNode);
          _pendingInteractionNodeId = null;
        }

        // The user turn that was in flight did not reach the agent. Marking
        // it failed is what stops an undelivered message from sitting in the
        // transcript looking exactly like a delivered one (A-03).
        var messages = _markPendingUserMessage(AiChatMessageStatus.failed);

        final activeId = activeStream.messageId;
        if (activeId != null) {
          activeStream.finish();
          messages = [
            for (final m in messages)
              if (m.id == activeId)
                m.copyWith(status: AiChatMessageStatus.failed)
              else
                m,
          ];
        }
        emit(
          state.copyWith(
            isTyping: false,
            // A fresh id per occurrence, so two identical failures in a row
            // both reach the snackbar. Keying the listener off the message
            // text is exactly what made every failure after the first silent.
            failure: AiChatFailure(
              id: 'failure_${generateUuidV4()}',
              message: message ?? 'errors.unknown',
            ),
            messages: messages,
          ),
        );
    }
  }

  /// Moves the in-flight user turn to [status] and clears the pending id.
  ///
  /// Returns the current list untouched when nothing is in flight, so callers
  /// can use it unconditionally.
  List<AiChatMessage> _markPendingUserMessage(AiChatMessageStatus status) {
    final pending = _pendingUserMessageId;
    if (pending == null) return state.messages;
    _pendingUserMessageId = null;
    return _replace(pending, (m) => m.copyWith(status: status));
  }

  List<AiChatMessage> _attachUi(
    String messageId,
    Map<String, dynamic> payload,
  ) {
    final result = _validator.validate(payload);
    _diagnostics.reportAll(result.diagnostics);

    if (!result.hasRenderableUi) {
      // Everything was rejected. The bubble keeps whatever prose came with the
      // message — the conversation continues either way.
      return state.messages;
    }
    return _replace(
      messageId,
      (message) => message.copyWith(document: result.document),
    );
  }

  List<AiChatMessage> _replace(
    String messageId,
    AiChatMessage Function(AiChatMessage) update,
  ) => [
    for (final message in state.messages)
      if (message.id == messageId) update(message) else message,
  ];

  @override
  Future<void> close() async {
    // Idempotent: a `ValueNotifier` asserts on a second dispose, and a bloc can
    // legitimately be closed more than once (a provider tearing down after a
    // test already closed it, for instance).
    if (_closed) return super.close();
    _closed = true;

    await _subscription?.cancel();
    _subscription = null;
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    activeStream.dispose();
    ledger.dispose();
    await _source.dispose();
    return super.close();
  }
}
