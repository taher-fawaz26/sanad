import 'package:asset_picker/asset_picker.dart';
import 'package:media_upload/media_upload.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/entities/ai_chat_attachment.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/entities/ai_uploaded_attachment.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_attachment_uploader.dart';

/// Uploads staged attachments through the shared `media_upload` pipeline.
///
/// The only file in the AI chat feature that names `media_upload`, and
/// therefore the only one that knows a multipart request exists. Nothing above
/// it sees an `UploadedMedia`, a `Failure`, or a `TaskEither`.
///
/// ## Why the upload does not ride the agent's own client
///
/// Two hosts, two auth schemes. The agent is `agent-<env>.trysanad.us`, reached
/// with a raw `Sanad-Access-Token` header and deliberately no interceptors;
/// `media/upload-single` is `<env>-api.trysanad.us/api/v1/` with Bearer auth,
/// refresh and retry supplied by `SecureDioClient`. Uploading over the agent's
/// bare Dio would mean re-implementing the second of those, which is exactly
/// the "new upload system" this reuses `media_upload` to avoid.
///
/// ## Sequential, and all or nothing
///
/// One request at a time: bounded memory, and it makes "stop at the first
/// failure" honest rather than racy. A failed batch is never sent partially —
/// a turn carrying three of five attachments is a message the user did not
/// write. Whatever already landed is left where it is; the client cannot
/// withdraw it, because `DELETE /media/{id}` is provider-only.
final class MediaUploadAiAttachmentUploader implements AiAttachmentUploader {
  /// Creates the uploader.
  const MediaUploadAiAttachmentUploader({
    required MediaUploadRepository repository,
  }) : _repository = repository;

  final MediaUploadRepository _repository;

  /// Adapts one staged attachment to the shape the upload pipeline takes.
  ///
  /// Pure and static so the mapping is assertable without a network, in the
  /// same shape as `SpeechToTextRecognizer.mapError`.
  ///
  /// The classification comes from `AssetType.fromMimeType` rather than a table
  /// of our own: `asset_picker` already owns that vocabulary, and a second copy
  /// would drift from it.
  ///
  /// A recording's `sizeBytes` is the documented `1` stub the composer sets —
  /// harmless, because the repository uploads from `path` and never reads
  /// `size`. It is carried through rather than recomputed so that no bloc and
  /// no adapter in this feature has to touch `dart:io`.
  static PickedAsset assetFor(AiChatAttachment attachment) => PickedAsset(
    name: attachment.fileName,
    path: attachment.localPath,
    mimeType: attachment.mimeType,
    size: attachment.sizeBytes,
    assetType: AssetType.fromMimeType(attachment.mimeType),
  );

  @override
  Future<AiAttachmentUploadResult> upload(
    List<AiChatAttachment> attachments,
  ) async {
    // No I/O for a turn with nothing attached, so a text-only send costs
    // exactly what it always did even with an uploader wired in.
    if (attachments.isEmpty) return const AiAttachmentsUploaded([]);

    final uploaded = <AiUploadedAttachment>[];

    for (final attachment in attachments) {
      AiUploadedAttachment? result;
      try {
        // Keyed by the attachment's own id, which is stable for its lifetime,
        // so the pipeline's per-key cancellation lines up with what the user
        // sees.
        final either = await _repository
            .upload(uploadKey: attachment.id, asset: assetFor(attachment))
            .run();

        result = either.match(
          // The `Failure` stops here. Its message may be raw backend prose,
          // and a bubble must never show that — see the localization rules.
          (_) => null,
          (media) => AiUploadedAttachment(
            source: attachment,
            mediaId: media.mediaId,
            url: media.url,
          ),
        );
      } on Object {
        // Totality: this seam never throws, whatever the pipeline does.
        result = null;
      }

      if (result == null) {
        return AiAttachmentUploadFailed(
          AiAttachmentUploadFailureKeys.failed,
          uploaded: uploaded,
        );
      }

      uploaded.add(result);
    }

    return AiAttachmentsUploaded(uploaded);
  }
}
