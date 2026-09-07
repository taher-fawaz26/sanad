import 'package:core/core.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/entities/ai_chat_attachment.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/enums/ai_attachment_status.dart';

/// What an attachment is allowed to be.
///
/// A value object rather than literals scattered through widgets, so the rules
/// are testable and a product change is one edit.
final class AiAttachmentRules {
  /// Creates a rule set.
  const AiAttachmentRules({
    this.maxAttachments = 5,
    this.maxRecordingDuration = const Duration(minutes: 5),
    this.documentExtensions = const {
      'pdf',
      'doc',
      'docx',
      'xls',
      'xlsx',
      'txt',
    },
  });

  /// The most attachments one message may carry.
  final int maxAttachments;

  /// The longest voice note that may be recorded.
  ///
  /// Five minutes rather than an arbitrary round number: AAC at ~32 kbps mono
  /// is roughly 4 KB/s, so five minutes lands near 1.2 MB — comfortably inside
  /// [maxSizeBytes] with room for a worse-case bitrate. This is how the
  /// recording path stays within the file-size ceiling without the UI policing
  /// it mid-take.
  final Duration maxRecordingDuration;

  /// Document extensions the composer accepts.
  final Set<String> documentExtensions;

  /// The hard per-file ceiling.
  ///
  /// Delegates to [FileSizePolicy], the repo-wide 5 MiB limit. Deliberately
  /// not a local constant and deliberately not loosened: every other upload
  /// path in the app clamps through the same policy, and an attachment that
  /// slipped past it would be the one file the backend later rejects.
  int get maxSizeBytes => FileSizePolicy.maxBytes;
}

/// Why an attachment was rejected. Each value is a localization key.
abstract final class AiAttachmentFailureKeys {
  /// The file is over [AiAttachmentRules.maxSizeBytes].
  static const tooLarge = 'ai_chat.attachment_too_large';

  /// The extension or MIME type is not accepted.
  static const unsupportedType = 'ai_chat.attachment_unsupported_type';

  /// The message already holds [AiAttachmentRules.maxAttachments].
  static const tooMany = 'ai_chat.attachment_too_many';

  /// The file is empty or unreadable.
  static const unreadable = 'ai_chat.attachment_unreadable';
}

/// Checks one attachment against [AiAttachmentRules].
///
/// Pure and synchronous: no file system, no plugins, no `Future`. That is what
/// makes the whole rule set exhaustively testable, including the exact
/// boundary at [FileSizePolicy.maxBytes].
final class ValidateAttachment {
  /// Creates the use case.
  const ValidateAttachment({this.rules = const AiAttachmentRules()});

  /// The rules to apply.
  final AiAttachmentRules rules;

  /// Returns [attachment] marked `ready`, or `failed` with a key.
  ///
  /// [currentCount] is how many attachments the composer already holds, so the
  /// count rule is enforced here rather than in the bloc.
  AiChatAttachment call(
    AiChatAttachment attachment, {
    required int currentCount,
  }) {
    if (currentCount >= rules.maxAttachments) {
      return attachment.withStatus(
        AiAttachmentStatus.failed,
        failureKey: AiAttachmentFailureKeys.tooMany,
      );
    }

    if (attachment.sizeBytes <= 0) {
      return attachment.withStatus(
        AiAttachmentStatus.failed,
        failureKey: AiAttachmentFailureKeys.unreadable,
      );
    }

    // `>` and not `>=`: a file exactly at the ceiling is allowed, matching
    // `FileSizePolicy.isValid`.
    if (attachment.sizeBytes > rules.maxSizeBytes) {
      return attachment.withStatus(
        AiAttachmentStatus.failed,
        failureKey: AiAttachmentFailureKeys.tooLarge,
      );
    }

    final typeFailure = switch (attachment) {
      AiImageAttachment() =>
        attachment.mimeType.startsWith('image/')
            ? null
            : AiAttachmentFailureKeys.unsupportedType,
      AiDocumentAttachment(:final extension) =>
        rules.documentExtensions.contains(extension.toLowerCase())
            ? null
            : AiAttachmentFailureKeys.unsupportedType,
      // Audio never comes from a picker — the recorder produces it — so there
      // is no untrusted extension to police.
      AiAudioAttachment() => null,
    };

    if (typeFailure != null) {
      return attachment.withStatus(
        AiAttachmentStatus.failed,
        failureKey: typeFailure,
      );
    }

    return attachment.withStatus(AiAttachmentStatus.ready);
  }
}
