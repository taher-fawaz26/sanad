import 'dart:async';

import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/ai_ui_renderer.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/ai_chat_event_source.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/ai_chat_message.dart';
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
  }) : _source = source,
       _validator = validator,
       _diagnostics = diagnostics,
       activeStream = activeStream ?? ActiveStreamController(),
       super(const AiChatState()) {
    on<AiChatStarted>(_onStarted);
    on<AiChatMessageSubmitted>(_onSubmitted, transformer: droppable());
    on<AiChatTransportEventReceived>(_onTransportEvent);
  }

  final AiChatEventSource _source;
  final AiUiValidator _validator;
  final AiUiDiagnosticsSink _diagnostics;

  /// Exposed so the streaming bubble can listen directly, bypassing the bloc's
  /// state entirely for per-token updates.
  final ActiveStreamController activeStream;

  StreamSubscription<AiChatEvent>? _subscription;

  bool _closed = false;

  Future<void> _onStarted(
    AiChatStarted event,
    Emitter<AiChatState> emit,
  ) async {
    await _subscription?.cancel();
    _subscription = _source.events.listen(
      (transportEvent) => add(AiChatTransportEventReceived(transportEvent)),
    );
    emit(state.copyWith(status: RequestStatus.success));
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

    emit(
      state.copyWith(
        messages: [
          ...state.messages,
          AiChatMessage.user(
            id: 'user_${generateUuidV4()}',
            text: text,
            attachments: attachments,
            createdAt: DateTime.now(),
          ),
        ],
      ),
    );

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

  void _onTransportEvent(
    AiChatTransportEventReceived event,
    Emitter<AiChatState> emit,
  ) {
    switch (event.event) {
      case AiChatMessageStartEvent(:final messageId?):
        activeStream.start(messageId);
        emit(
          state.copyWith(
            isTyping: false,
            messages: [
              ...state.messages,
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
        final activeId = activeStream.messageId;
        if (activeId != null) activeStream.finish();
        emit(
          state.copyWith(
            isTyping: false,
            failureMessage: message,
            messages: activeId == null
                ? state.messages
                : _replace(
                    activeId,
                    (m) => m.copyWith(status: AiChatMessageStatus.failed),
                  ),
          ),
        );
    }
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
    activeStream.dispose();
    await _source.dispose();
    return super.close();
  }
}
