import 'package:equatable/equatable.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/entities/ai_chat_attachment.dart';

/// One user turn on its way out.
///
/// The composer produces this; the conversation consumes it. It exists so a
/// turn is a single value rather than a widening parameter list, and so a
/// transport that understands attachments and one that does not can be handed
/// the same thing.
final class AiOutgoingMessage extends Equatable {
  /// Creates an outgoing turn.
  const AiOutgoingMessage({
    this.text = '',
    this.attachments = const [],
  });

  /// What the user typed. Already trimmed by the composer.
  final String text;

  /// Everything attached, all of it `ready` — the composer never submits an
  /// attachment that is still being prepared or that failed.
  final List<AiChatAttachment> attachments;

  /// Whether anything is attached.
  bool get hasAttachments => attachments.isNotEmpty;

  /// Whether there is nothing to send.
  ///
  /// Audio-only and image-only turns are legitimate, so an empty [text] alone
  /// does not make a turn empty.
  bool get isEmpty => text.isEmpty && attachments.isEmpty;

  @override
  List<Object?> get props => [text, attachments];
}
