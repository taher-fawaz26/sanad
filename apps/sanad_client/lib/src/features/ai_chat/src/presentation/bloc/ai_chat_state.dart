part of 'ai_chat_bloc.dart';

/// The conversation as the UI sees it.
///
/// Note what is *not* here: streaming text. A partially written reply lives in
/// [AiChatBloc.activeStream] so a token cannot cause a new state, and therefore
/// cannot rebuild the message list.
final class AiChatState extends Equatable {
  /// Creates a chat state.
  const AiChatState({
    this.status = RequestStatus.initial,
    this.messages = const [],
    this.isTyping = false,
    this.failureMessage,
  });

  /// Lifecycle of the connection to the event source.
  final RequestStatus status;

  /// Oldest first. The list renders reversed so a new message appears at the
  /// bottom without re-laying-out the conversation.
  final List<AiChatMessage> messages;

  /// Whether the agent has signalled that a reply is coming.
  final bool isTyping;

  /// Agent-side error prose, already localized by the agent.
  final String? failureMessage;

  /// True when there is nothing to show yet.
  bool get isEmpty => messages.isEmpty;

  /// Whether Home should render its **landing** composition — the hero mark
  /// and the starter suggestions — rather than a conversation.
  ///
  /// One canonical answer to "has the conversation started?", derived from
  /// the conversation itself. The hero, the suggestions and the message list
  /// all read this same getter, so the three can never disagree about which
  /// composition the screen is in.
  ///
  /// [isTyping] is part of it because the turn has already begun the moment
  /// the agent signals a reply: the first token can land before any message
  /// exists, and a hero that reappeared in that gap would flicker back in
  /// behind the incoming answer.
  ///
  /// Deliberately **not** a function of composer focus. Focusing the field is
  /// not starting a conversation — the landing composition survives the
  /// keyboard opening, and only an actual turn replaces it.
  bool get showsLanding => isEmpty && !isTyping;

  /// Returns a copy with the given fields replaced.
  AiChatState copyWith({
    RequestStatus? status,
    List<AiChatMessage>? messages,
    bool? isTyping,
    String? failureMessage,
  }) => AiChatState(
    status: status ?? this.status,
    messages: messages ?? this.messages,
    isTyping: isTyping ?? this.isTyping,
    failureMessage: failureMessage ?? this.failureMessage,
  );

  @override
  List<Object?> get props => [status, messages, isTyping, failureMessage];
}
