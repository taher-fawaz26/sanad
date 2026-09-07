import 'package:equatable/equatable.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/entities/ai_chat_attachment.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/entities/ai_uploaded_attachment.dart';

/// Localization keys this seam can fail with.
abstract final class AiAttachmentUploadFailureKeys {
  AiAttachmentUploadFailureKeys._();

  /// The batch did not reach storage. Deliberately the only one: the user can
  /// do exactly one thing about a failed upload — send again — so splitting it
  /// into network/server/timeout variants would add prose, not choices.
  static const String failed = 'ai_chat.attachment_upload_failed';
}

/// The outcome of one upload batch.
///
/// A sealed result rather than a `TaskEither`, matching `AiAttachmentSource`
/// and every other device seam in this feature: `fpdart` stops at the data
/// layer, and a `Failure` carrying backend prose must never reach a bubble.
sealed class AiAttachmentUploadResult extends Equatable {
  const AiAttachmentUploadResult();

  @override
  List<Object?> get props => [];
}

/// Every attachment reached storage, in the order they were handed over.
final class AiAttachmentsUploaded extends AiAttachmentUploadResult {
  /// Creates a successful batch.
  const AiAttachmentsUploaded(this.attachments);

  /// One entry per input, each carrying its `id` and resolved `url`.
  final List<AiUploadedAttachment> attachments;

  @override
  List<Object?> get props => [attachments];
}

/// The batch did not complete. [failureKey] is a localization key, never prose.
final class AiAttachmentUploadFailed extends AiAttachmentUploadResult {
  /// Creates a failure carrying a localization key.
  const AiAttachmentUploadFailed(
    this.failureKey, {
    this.uploaded = const [],
  });

  /// A dotted lower-snake i18n key.
  final String failureKey;

  /// Whatever reached storage before the batch was abandoned.
  ///
  /// Carried for diagnostics only — a partial batch is never sent. The client
  /// cannot clean these up: `DELETE /media/{id}` is provider-only, so they are
  /// the backend's to garbage-collect.
  final List<AiUploadedAttachment> uploaded;

  @override
  List<Object?> get props => [failureKey, uploaded];
}

/// Turns staged attachments into the `{id, url}` pairs a turn puts on the wire.
///
/// The implementation is the only thing in the feature that knows
/// `media_upload` exists, which is what lets both transports be tested with no
/// HTTP client and no storage.
///
/// ## All or nothing
///
/// A batch either uploads completely or fails. A turn that shipped three of
/// five attachments would be a message the user did not write, and the client
/// has no way to withdraw the three that landed.
// A one-member interface on purpose: it is the upload boundary, not a
// convenience — the seam is what a transport swaps out in a test.
// ignore: one_member_abstracts
abstract interface class AiAttachmentUploader {
  /// Uploads [attachments], preserving order.
  ///
  /// Never throws: every failure comes back as [AiAttachmentUploadFailed]. An
  /// empty list is a success carrying an empty list, and performs no I/O.
  Future<AiAttachmentUploadResult> upload(List<AiChatAttachment> attachments);
}

/// The uploader a transport gets when nobody supplied one.
///
/// Exists so [AiAttachmentUploader] can be an optional constructor parameter
/// with a `const` default, which is what keeps every existing transport
/// construction site — the probes, the tests, the screen — compiling unchanged.
///
/// It succeeds trivially for a turn with nothing attached, so a text-only send
/// through a transport with no uploader behaves exactly as it always did, and
/// refuses anything else rather than silently dropping it.
final class AiUnavailableAttachmentUploader implements AiAttachmentUploader {
  /// Creates the no-op uploader.
  const AiUnavailableAttachmentUploader();

  @override
  Future<AiAttachmentUploadResult> upload(
    List<AiChatAttachment> attachments,
  ) async => attachments.isEmpty
      ? const AiAttachmentsUploaded([])
      : const AiAttachmentUploadFailed(AiAttachmentUploadFailureKeys.failed);
}
