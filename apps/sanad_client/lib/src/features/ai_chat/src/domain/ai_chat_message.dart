import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:equatable/equatable.dart';

/// Who authored a message.
enum AiChatRole {
  /// Typed by the person, or posted on their behalf by a `send_message`
  /// action from a quick reply.
  user,

  /// Produced by the agent.
  assistant,
}

/// Lifecycle of an assistant message.
enum AiChatMessageStatus {
  /// Text is still arriving. The bubble reads from `ActiveStreamController`
  /// rather than from [AiChatMessage.text], which is what keeps a token from
  /// touching the message list at all.
  streaming,

  /// Finished; [AiChatMessage.text] is authoritative.
  complete,

  /// The agent reported an error mid-reply.
  failed,
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
  });

  /// Creates a user turn.
  const AiChatMessage.user({
    required this.id,
    required this.text,
    this.createdAt,
  }) : role = AiChatRole.user,
       document = null,
       status = AiChatMessageStatus.complete;

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

  /// Whether text is still arriving for this message.
  bool get isStreaming => status == AiChatMessageStatus.streaming;

  /// Whether there is structured UI worth drawing.
  bool get hasUi => document?.isNotEmpty ?? false;

  /// True when there is nothing at all to draw — used to decide whether a
  /// bubble is worth keeping after a payload was entirely rejected.
  bool get isEmpty => text.isEmpty && !hasUi && !isStreaming;

  /// Returns a copy with the given fields replaced.
  AiChatMessage copyWith({
    String? text,
    AiUiDocument? document,
    AiChatMessageStatus? status,
  }) => AiChatMessage(
    id: id,
    role: role,
    text: text ?? this.text,
    document: document ?? this.document,
    status: status ?? this.status,
    createdAt: createdAt,
  );

  @override
  List<Object?> get props => [id, role, text, document, status, createdAt];
}
