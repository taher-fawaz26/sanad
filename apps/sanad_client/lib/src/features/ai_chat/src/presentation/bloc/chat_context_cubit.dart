import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/ai_contextual_event_source.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/entities/chat_context_content.dart';

part 'chat_context_state.dart';

/// Owns **whether the conversation has contextual information to offer**, and
/// what it is.
///
/// Deliberately separate from `AiChatBloc`. The conversation's own state is on
/// the hot path — a streamed token must not be able to cause a state emission,
/// which is why `AiChatBloc` keeps streaming text outside its state entirely.
/// Hanging contextual content off the same bloc would put the context layer on
/// that path in the other direction: every message list rebuild would carry the
/// layer with it, and every context change would rebuild the conversation.
///
/// Separate cubit, separate rebuild boundary: the layer listens to this, the
/// message list listens to `AiChatBloc`, and dragging the layer cannot touch
/// the transcript.
///
/// ## Where the content comes from
///
/// From the transport, and only from the transport. A source that implements
/// [AiContextualEventSource] publishes payloads on a stream and this forwards
/// them; a source that does not leaves the cubit permanently empty, which is
/// exactly right for a transport whose agent has no side channel yet.
///
/// Nothing in the presentation layer may call [show] to invent content. The
/// method stays public for the one legitimate caller shape — a future
/// non-stream producer — and the context layer itself reads state, never
/// writes it.
///
/// It owns no presentation state at all: how far open the layer is, whether a
/// drag is in flight and which snap it settled on all belong to
/// `AiChatContextController`.
class ChatContextCubit extends Cubit<ChatContextState> {
  /// Starts with nothing to offer, which is the normal state of a
  /// conversation, and follows [source] when it has a contextual channel.
  ChatContextCubit({AiContextualEventSource? source})
    : super(const ChatContextState()) {
    final contextual = source;
    if (contextual == null) return;
    _subscription = contextual.contextualContent.listen(
      (content) => content == null ? clear() : show(content),
    );
  }

  StreamSubscription<ChatContextContent?>? _subscription;

  /// Publishes [content], replacing anything already there.
  ///
  /// Replacing rather than stacking: there is one contextual surface, and the
  /// most recent thing the agent produced is what it is about. A layer that is
  /// already open stays open and re-settles on the new payload's extent.
  void show(ChatContextContent content) =>
      emit(ChatContextState(content: content));

  /// Withdraws whatever is there. The layer animates out and disappears.
  void clear() => emit(const ChatContextState());

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
