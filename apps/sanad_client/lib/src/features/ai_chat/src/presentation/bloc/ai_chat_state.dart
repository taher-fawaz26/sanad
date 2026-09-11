part of 'ai_chat_bloc.dart';

/// One transport or agent failure, identified per occurrence.
///
/// The id exists because the previous design keyed the snackbar's
/// `listenWhen` off the failure *string*: a second identical failure left
/// `failureMessage` unchanged, so the listener never fired and every failure
/// after the first was silent (A-03). `AiComposerNotice` already solved this
/// for the composer; this is the same answer for the conversation.
final class AiChatFailure extends Equatable {
  /// Creates a failure.
  const AiChatFailure({required this.id, required this.message});

  /// Unique per occurrence, so a repeat still reads as a change.
  final String id;

  /// Agent-side prose, or a client i18n key.
  final String message;

  @override
  List<Object?> get props => [id, message];
}

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
    this.isOffline = false,
    this.failure,
  });

  /// Lifecycle of the connection to the event source.
  final RequestStatus status;

  /// Oldest first. The list renders reversed so a new message appears at the
  /// bottom without re-laying-out the conversation.
  final List<AiChatMessage> messages;

  /// Whether the agent has signalled that a reply is coming.
  final bool isTyping;

  /// Whether the device currently has no network.
  ///
  /// A *device* fact, not a transport one, which is why it is separate from
  /// [failure]: the composer stays usable either way, but while this is set a
  /// new turn is queued rather than attempted, and the conversation says so
  /// once instead of failing every send.
  final bool isOffline;

  /// The most recent failure, or null. Carries a per-occurrence id so two
  /// identical failures in a row both surface.
  final AiChatFailure? failure;

  /// True when there is nothing to show yet.
  bool get isEmpty => messages.isEmpty;

  /// Turns held on the device waiting for a connection, oldest first.
  Iterable<AiChatMessage> get queuedMessages =>
      messages.where((message) => message.status.isQueued);

  /// Whether any user turn was attempted and did not reach the agent.
  ///
  /// Drives the send-failure banner. Deliberately *not* derived from
  /// [failure], which also covers agent-side errors that did reach it and
  /// which is transient by design — a bubble left undelivered is neither.
  bool get hasUndeliveredMessage =>
      messages.any((message) => message.status.isFailed && message.isFromUser);

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
    bool? isOffline,
    AiChatFailure? failure,
  }) => AiChatState(
    status: status ?? this.status,
    messages: messages ?? this.messages,
    isTyping: isTyping ?? this.isTyping,
    isOffline: isOffline ?? this.isOffline,
    failure: failure ?? this.failure,
  );

  @override
  List<Object?> get props => [
    status,
    messages,
    isTyping,
    isOffline,
    failure,
  ];
}
