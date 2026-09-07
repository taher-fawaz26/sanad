import 'package:equatable/equatable.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/entities/ai_chat_attachment.dart';

/// One attachment that has been uploaded and is ready to name on the wire.
///
/// ## Why this wraps an attachment instead of widening one
///
/// [AiChatAttachment] lives in `AiChatMessage.attachments` for as long as the
/// conversation does; upload identity is valid for exactly one request.
/// Putting [mediaId] and [url] on the entity would give a
/// conversation-lifetime object a pair of fields that expire underneath it,
/// and — because a message's `props` include its attachments — would re-emit
/// the whole message list the moment an upload resolved. So the send path
/// mints one of these, uses it, and drops it.
///
/// It is also why no widget can render a URL by accident: this type never
/// reaches the presentation layer.
final class AiUploadedAttachment extends Equatable {
  /// Creates an uploaded attachment.
  const AiUploadedAttachment({
    required this.source,
    required this.mediaId,
    required this.url,
  });

  /// The staged attachment this was uploaded from.
  ///
  /// Kept so the serializer can ask what kind of thing it is — an audio note
  /// carries its transcript on the wire, a photo does not — without a second
  /// lookup or a parallel list to keep in step.
  final AiChatAttachment source;

  /// The backend's opaque identifier for the stored file.
  final String mediaId;

  /// Where the backend resolved the file to.
  ///
  /// Sent alongside [mediaId] so the agent never performs a storage lookup to
  /// find a file the client already knows the location of. Treated as opaque
  /// and single-use: nothing caches it, and nothing reuses it across turns, so
  /// a short-lived signed URL and a permanent one behave identically here.
  final String url;

  @override
  List<Object?> get props => [source, mediaId, url];
}
