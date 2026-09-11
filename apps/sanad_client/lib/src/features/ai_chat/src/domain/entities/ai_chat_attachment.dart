import 'package:equatable/equatable.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/enums/ai_attachment_status.dart';

/// One thing the user attached to a message.
///
/// ## Why a path and never bytes
///
/// [localPath] points at a file on disk; there is no `bytes` field anywhere in
/// this hierarchy. Holding file bytes in a domain object would mean a second
/// copy alive for as long as the message is in the list, which for a
/// conversation with a few photos is tens of megabytes of avoidable heap. The
/// picker is configured with `loadBytes: false` for the same reason, and a
/// preview widget reads the file lazily.
///
/// ## Why it carries no backend field
///
/// Still no upload id, no remote URL, no progress. Upload identity is a
/// *transport* fact with the lifetime of a single send — the send path mints
/// it, uses it and throws it away — so it lives on `AiUploadedAttachment`,
/// which wraps one of these rather than widening it. A message that outlives
/// its turn must not hold a location-shaped string that can expire under it.
///
/// ## Why there is no audio variant
///
/// AI Chat does not send recorded audio. Its one voice input method is
/// Speech-to-Text, which produces editable composer text and reaches the agent
/// as an ordinary text message — never a file, never an attachment. An
/// `AiAudioAttachment` existed here once, carrying a duration, a waveform and
/// an on-device transcript; the capability was retired, so the variant went
/// with it rather than sitting dormant for something to pick up again.
sealed class AiChatAttachment extends Equatable {
  const AiChatAttachment({
    required this.id,
    required this.fileName,
    required this.sizeBytes,
    required this.mimeType,
    required this.localPath,
    this.status = AiAttachmentStatus.picked,
    this.failureKey,
  });

  /// Stable for the life of the attachment. Used as the widget key, so a
  /// status change repaints one tile instead of reshuffling the row.
  final String id;

  /// Display name including extension, e.g. `receipt.pdf`.
  final String fileName;

  /// Size on disk. Checked against `FileSizePolicy`, never against a literal.
  final int sizeBytes;

  /// Best-effort MIME type from the picker.
  final String mimeType;

  /// Absolute path on the device file system.
  final String localPath;

  /// Where this attachment is in its lifecycle.
  final AiAttachmentStatus status;

  /// A localization key when [status] is `failed`.
  ///
  /// A key, never a message and never a platform exception string: the domain
  /// does not know what language the user reads, and a raw `PlatformException`
  /// must never reach a bubble.
  final String? failureKey;

  /// Whether this attachment may be included in a submitted message.
  bool get isReady => status.isReady;

  /// Returns a copy in [status], optionally carrying [failureKey].
  ///
  /// The only mutation the composer performs. Implemented per subtype because
  /// each carries different derived metadata.
  AiChatAttachment withStatus(
    AiAttachmentStatus status, {
    String? failureKey,
  });

  @override
  List<Object?> get props => [
    id,
    fileName,
    sizeBytes,
    mimeType,
    localPath,
    status,
    failureKey,
  ];
}

/// A photo or picked image.
///
/// Carries no width, height or thumbnail path on purpose. The picker reports
/// none of them, so they could only be produced by decoding the file — and the
/// preview does not need them: it decodes at reduced resolution via
/// `cacheWidth`, which costs less than generating and tracking a second file.
/// Three permanently-null fields would be model, not information.
final class AiImageAttachment extends AiChatAttachment {
  /// Creates an image attachment.
  const AiImageAttachment({
    required super.id,
    required super.fileName,
    required super.sizeBytes,
    required super.mimeType,
    required super.localPath,
    super.status,
    super.failureKey,
  });

  @override
  AiImageAttachment withStatus(
    AiAttachmentStatus status, {
    String? failureKey,
  }) => AiImageAttachment(
    id: id,
    fileName: fileName,
    sizeBytes: sizeBytes,
    mimeType: mimeType,
    localPath: localPath,
    status: status,
    failureKey: failureKey ?? this.failureKey,
  );
}

/// A picked document — PDF, Word, Excel or plain text.
final class AiDocumentAttachment extends AiChatAttachment {
  /// Creates a document attachment.
  const AiDocumentAttachment({
    required super.id,
    required super.fileName,
    required super.sizeBytes,
    required super.mimeType,
    required super.localPath,
    required this.extension,
    super.status,
    super.failureKey,
  });

  /// Lower-cased, without the dot, e.g. `pdf`. Drives the tile's icon.
  final String extension;

  @override
  AiDocumentAttachment withStatus(
    AiAttachmentStatus status, {
    String? failureKey,
  }) => copyWith(status: status, failureKey: failureKey);

  /// Returns a copy with the given fields replaced.
  AiDocumentAttachment copyWith({
    AiAttachmentStatus? status,
    String? failureKey,
  }) => AiDocumentAttachment(
    id: id,
    fileName: fileName,
    sizeBytes: sizeBytes,
    mimeType: mimeType,
    localPath: localPath,
    extension: extension,
    status: status ?? this.status,
    failureKey: failureKey ?? this.failureKey,
  );

  @override
  List<Object?> get props => [...super.props, extension];
}
