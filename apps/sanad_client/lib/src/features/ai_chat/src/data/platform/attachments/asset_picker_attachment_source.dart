import 'package:asset_picker/asset_picker.dart';
import 'package:core/core.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/entities/ai_chat_attachment.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_attachment_source.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_permission_gateway.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/usecases/validate_attachment.dart';

/// Acquires images and documents through the shared `asset_picker`.
///
/// The only file in the AI chat feature that names `asset_picker`, and
/// therefore the only one that transitively knows `image_picker` and
/// `file_picker` exist. Nothing above it sees a `PickedAsset`.
///
/// ## Why this reuses the picker rather than wrapping the plugins
///
/// `asset_picker` already owns acquisition, compression, MIME resolution and
/// the source sheet, and the provider app has been through several rounds of
/// bug-fixing in it (SAN-576, SAN-781). Re-implementing any of that here would
/// mean re-learning those bugs.
final class AssetPickerAttachmentSource implements AiAttachmentSource {
  /// Creates the source.
  const AssetPickerAttachmentSource({
    required AiPermissionGateway permissions,
    AiAttachmentRules rules = const AiAttachmentRules(),
  }) : _permissions = permissions,
       _rules = rules;

  final AiPermissionGateway _permissions;
  final AiAttachmentRules _rules;

  @override
  Future<AiAttachmentPickResult> pick(AiAttachmentIntent intent) async {
    final denial = await _ensurePermission(intent);
    if (denial != null) return denial;

    try {
      final result = switch (intent) {
        AiAttachmentIntent.camera => await AssetPicker.pickCamera(
          options: _optionsFor(intent),
        ),
        AiAttachmentIntent.gallery => await AssetPicker.pickGallery(
          options: _optionsFor(intent),
        ),
        AiAttachmentIntent.document => await AssetPicker.pickFile(
          options: _optionsFor(intent),
        ),
      };

      if (result.cancelled || result.isEmpty) {
        return const AiAttachmentPickCancelled();
      }

      return AiAttachmentsPicked([
        for (final asset in result.assets) _toAttachment(asset),
      ]);
    } on AssetPermissionDeniedException catch (error) {
      // The picker can refuse even after our own check — a race, or a
      // platform that only reports the truth at open time.
      return AiAttachmentPickDenied(permanently: error.permanentlyDenied);
    } on AssetValidationException {
      return const AiAttachmentPickFailed(
        AiAttachmentFailureKeys.unsupportedType,
      );
    } on AssetSourceUnavailableException {
      return const AiAttachmentPickFailed(
        'ai_chat.attachment_source_unavailable',
      );
    } on Object {
      // Total by contract: a platform failure becomes a localization key, and
      // the exception's own message — which can name a file path — never
      // reaches the UI.
      return const AiAttachmentPickFailed('ai_chat.attachment_pick_failed');
    }
  }

  Future<AiAttachmentPickResult?> _ensurePermission(
    AiAttachmentIntent intent,
  ) async {
    // Documents need no runtime permission on either platform — the system
    // file picker hands back a scoped URI. This mirrors what
    // `MediaPermissions.ensureFor` already does for `AssetSource.files`.
    final outcome = switch (intent) {
      AiAttachmentIntent.camera => await _permissions.ensureCamera(),
      AiAttachmentIntent.gallery => await _permissions.ensureGallery(),
      AiAttachmentIntent.document => AiPermissionOutcome.granted,
    };

    return switch (outcome) {
      AiPermissionOutcome.granted => null,
      AiPermissionOutcome.denied => const AiAttachmentPickDenied(
        permanently: false,
      ),
      AiPermissionOutcome.permanentlyDenied => const AiAttachmentPickDenied(
        permanently: true,
      ),
      AiPermissionOutcome.unavailable => const AiAttachmentPickFailed(
        'ai_chat.attachment_source_unavailable',
      ),
    };
  }

  /// Builds the picker options for [intent].
  ///
  /// One builder rather than three constants so the guarantees this feature
  /// depends on are stated once and cannot drift apart.
  ///
  /// Two decisions worth naming:
  ///
  /// * `enforceSizeBeforeCompression` is **on for documents only**. A camera
  ///   photo is routinely over the 5 MiB ceiling before compression and
  ///   comfortably under it after, so validating the original would reject
  ///   perfectly usable photos. A PDF has nothing to compress, so it must be
  ///   measured at its true size or an oversized file would slip through a
  ///   pipeline that never ran on it.
  /// * `loadBytes` is **never** enabled. The file stays on disk and nothing
  ///   holds a second copy in memory — the whole reason `AiChatAttachment`
  ///   carries a path and no bytes.
  AssetPickerOptions _optionsFor(AiAttachmentIntent intent) {
    final isDocument = intent == AiAttachmentIntent.document;
    final isCamera = intent == AiAttachmentIntent.camera;

    return AssetPickerOptions(
      allowCamera: isCamera,
      allowGallery: intent == AiAttachmentIntent.gallery,
      allowFiles: isDocument,
      // A camera capture is one photo by definition; the other sources are
      // bounded by how many attachments a message may carry.
      allowMultiple: !isCamera,
      maxSelection: isCamera ? 1 : _rules.maxAttachments,
      maxFileSize: _rules.maxSizeBytes,
      allowedExtensions: isDocument ? _rules.documentExtensions.toList() : null,
      allowedAssetTypes: isDocument ? null : const [AssetType.image],
      enforceSizeBeforeCompression: isDocument,
      // Stated even though it matches the default: this is a memory posture,
      // not an omission.
      // ignore: avoid_redundant_argument_values
      loadBytes: false,
    );
  }

  /// Normalises a picked asset into the feature's own model.
  ///
  /// Everything arrives as `picked`; validation is a separate, pure step so
  /// the rules stay testable without a picker.
  AiChatAttachment _toAttachment(PickedAsset asset) {
    final id = 'att_${generateUuidV4()}';

    if (asset.assetType == AssetType.image) {
      return AiImageAttachment(
        id: id,
        fileName: asset.name,
        sizeBytes: asset.size,
        mimeType: asset.mimeType,
        localPath: asset.path,
      );
    }

    return AiDocumentAttachment(
      id: id,
      fileName: asset.name,
      sizeBytes: asset.size,
      mimeType: asset.mimeType,
      localPath: asset.path,
      extension: asset.extension,
    );
  }
}
