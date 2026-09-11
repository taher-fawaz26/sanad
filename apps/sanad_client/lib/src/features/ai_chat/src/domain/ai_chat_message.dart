import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:equatable/equatable.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/entities/ai_chat_attachment.dart';

/// Who authored a message.
enum AiChatRole {
  /// Typed by the person, or posted on their behalf by a `send_message`
  /// action from a quick reply.
  user,

  /// Produced by the agent.
  assistant,
}

/// Lifecycle of a message.
///
/// Shared by both roles. An assistant bubble moves
/// `streaming → complete | failed`; a user bubble moves
/// `queued? → sending → complete | failed`, which is what lets a turn that
/// never reached the agent look different from one that did (A-03).
///
/// ## Why [queued] is not [failed], and not [sending] either
///
/// The three describe three different facts, and the reference design draws
/// three different things for them:
///
/// * [queued] — the device has no connection, so the turn was never handed to
///   the transport. It *will* be, the moment there is one. Nothing has gone
///   wrong, and telling the user it has would be a lie they would act on.
/// * [sending] — handed over, outcome unknown.
/// * [failed] — the send was attempted and the agent did not get it.
///
/// Collapsing [queued] into [sending] would show a turn as on its way while
/// the radio is off; collapsing it into [failed] would offer a Retry that
/// cannot succeed. So the queue is a state of its own, and the only thing
/// that moves a turn out of it is connectivity coming back.
enum AiChatMessageStatus {
  /// Held on the device because there is no connection. Not yet handed to the
  /// transport, and not a failure.
  queued,

  /// A user turn handed to the transport, not yet known to have arrived.
  sending,

  /// Text is still arriving. The bubble reads from `ActiveStreamController`
  /// rather than from [AiChatMessage.text], which is what keeps a token from
  /// touching the message list at all.
  streaming,

  /// Finished; [AiChatMessage.text] is authoritative.
  complete,

  /// The agent reported an error mid-reply, or a user turn never reached it.
  failed,
}

/// Convenience predicates, so widgets read intent rather than enum equality.
extension AiChatMessageStatusX on AiChatMessageStatus {
  /// Whether this turn is still in flight.
  bool get isSending => this == AiChatMessageStatus.sending;

  /// Whether this turn is waiting for a connection before it is sent.
  bool get isQueued => this == AiChatMessageStatus.queued;

  /// Whether this turn did not make it.
  bool get isFailed => this == AiChatMessageStatus.failed;

  /// Whether the turn has not reached the agent yet, for whatever reason.
  ///
  /// What the bubble's held-back opacity keys off, since a queued turn and one
  /// still on the wire look the same *as content* — only their footers differ.
  bool get isUndelivered => isSending || isQueued;

  /// Whether the user may ask for this turn to be sent again.
  ///
  /// A queued turn is retryable too: tapping Retry while offline is a
  /// legitimate "try now", and it costs a connectivity re-check rather than
  /// nothing.
  bool get isRetryable => isFailed || isQueued;
}

/// One bubble in the conversation.
///
/// [document] is an *already validated* protocol document, parsed once when the
/// `ui` event arrived. Nothing downstream ever re-parses JSON, and in
/// particular nothing parses inside `build()`.
final class AiChatMessage extends Equatable {
  /// Creates a message.
  const AiChatMessage({
    required this.id,
    required this.role,
    this.text = '',
    this.document,
    this.status = AiChatMessageStatus.complete,
    this.createdAt,
    this.attachments = const [],
    this.interaction,
  });

  /// Creates a user turn.
  ///
  /// Defaults to [AiChatMessageStatus.sending]: a turn is only known to have
  /// landed once the agent answers it. Before A-03 this was hardcoded to
  /// `complete`, which is why a message that never left the device was
  /// indistinguishable from one the agent had replied to.
  const AiChatMessage.user({
    required this.id,
    required this.text,
    this.createdAt,
    this.attachments = const [],
    this.interaction,
    this.status = AiChatMessageStatus.sending,
  }) : role = AiChatRole.user,
       document = null;

  /// Stable identity, used as the list item's widget key.
  final String id;

  /// Who wrote it.
  final AiChatRole role;

  /// Authoritative text once [status] is not [AiChatMessageStatus.streaming].
  final String text;

  /// Validated structured UI, parsed once when the `ui` event arrived.
  final AiUiDocument? document;

  /// Where this message is in its lifecycle.
  final AiChatMessageStatus status;

  /// When the client first saw the message.
  final DateTime? createdAt;

  /// Images and documents sent with this turn.
  ///
  /// Never audio: AI Chat sends no recorded audio, so nothing here can be a
  /// voice note. Speech reaches a turn as ordinary text in [text].
  ///
  /// Defaults to empty, which is what makes this an additive change: every
  /// existing construction site keeps compiling and every text-only message
  /// behaves exactly as before. One conversation holds every modality — an
  /// image turn, a voice turn and a document turn sit in the same list.
  final List<AiChatAttachment> attachments;

  /// The structured answer this turn *is*, when it came from tapping a
  /// semantic card rather than from typing.
  ///
  /// Kept on the message rather than discarded after sending: it is the record
  /// of which node was answered and with what, which is what lets the bubble
  /// be rendered differently later and what makes a replayed conversation
  /// reconstructible. `null` for every typed turn and every assistant turn.
  final AiUiInteraction? interaction;

  /// Whether the person wrote this turn.
  bool get isFromUser => role == AiChatRole.user;

  /// Whether this turn carries anything but text.
  bool get hasAttachments => attachments.isNotEmpty;

  /// Whether this turn answered a semantic card.
  bool get isInteraction => interaction != null;

  /// Whether text is still arriving for this message.
  bool get isStreaming => status == AiChatMessageStatus.streaming;

  /// Whether there is structured UI worth drawing.
  bool get hasUi => document?.isNotEmpty ?? false;

  /// True when there is nothing at all to draw — used to decide whether a
  /// bubble is worth keeping after a payload was entirely rejected.
  bool get isEmpty =>
      text.isEmpty && !hasUi && !isStreaming && attachments.isEmpty;

  /// Returns a copy with the given fields replaced.
  AiChatMessage copyWith({
    String? text,
    AiUiDocument? document,
    AiChatMessageStatus? status,
    List<AiChatAttachment>? attachments,
  }) => AiChatMessage(
    id: id,
    role: role,
    text: text ?? this.text,
    document: document ?? this.document,
    status: status ?? this.status,
    createdAt: createdAt,
    attachments: attachments ?? this.attachments,
    interaction: interaction,
  );

  // `attachments` must stay in here: the message list rebuilds on
  // `previous.messages != current.messages`, so a field left out of `props`
  // would render once and then silently never update.
  @override
  List<Object?> get props => [
    id,
    role,
    text,
    document,
    status,
    createdAt,
    attachments,
    interaction,
  ];
}
