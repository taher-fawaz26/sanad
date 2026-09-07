import 'package:equatable/equatable.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/entities/ai_chat_attachment.dart';

/// Which acquisition flow the user asked for.
///
/// The composer emits one of these and nothing else — it does not know that a
/// camera plugin exists, which sheet to show, or what a MIME type is.
enum AiAttachmentIntent {
  /// Take a photo now.
  camera,

  /// Choose one or more existing photos.
  gallery,

  /// Choose a document.
  document,
}

/// The outcome of one acquisition attempt.
///
/// A sealed result rather than a nullable list plus an exception, so the bloc
/// handles cancellation, refusal and failure explicitly and a platform
/// exception can never escape the data layer.
sealed class AiAttachmentPickResult extends Equatable {
  const AiAttachmentPickResult();

  @override
  List<Object?> get props => [];
}

/// The user picked something. Every entry is `picked`, not yet validated.
final class AiAttachmentsPicked extends AiAttachmentPickResult {
  /// Creates a successful pick.
  const AiAttachmentsPicked(this.attachments);

  /// What was acquired, in selection order.
  final List<AiChatAttachment> attachments;

  @override
  List<Object?> get props => [attachments];
}

/// The user backed out. Not a failure; nothing is surfaced.
final class AiAttachmentPickCancelled extends AiAttachmentPickResult {
  /// Creates a cancellation.
  const AiAttachmentPickCancelled();
}

/// The capability was refused.
final class AiAttachmentPickDenied extends AiAttachmentPickResult {
  /// Creates a refusal, [permanently] when only settings can undo it.
  const AiAttachmentPickDenied({required this.permanently});

  /// Whether the UI should offer the settings path.
  final bool permanently;

  @override
  List<Object?> get props => [permanently];
}

/// The platform failed. [failureKey] is a localization key, never prose.
final class AiAttachmentPickFailed extends AiAttachmentPickResult {
  /// Creates a failure carrying a localization key.
  const AiAttachmentPickFailed(this.failureKey);

  /// A dotted lower-snake i18n key.
  final String failureKey;

  @override
  List<Object?> get props => [failureKey];
}

/// Acquires attachments from the device.
///
/// The implementation is the only thing in the feature that knows
/// `asset_picker` exists. Keeping this an interface is what lets the composer
/// bloc be tested with no picker, no permissions and no file system.
// A one-member interface on purpose: it is the plugin boundary, not a
// convenience. Collapsing it to a function would remove the seam that lets
// the composer bloc run with no picker, no permissions and no file system.
// ignore: one_member_abstracts
abstract interface class AiAttachmentSource {
  /// Runs the flow for [intent].
  ///
  /// Never throws: every platform failure comes back as
  /// [AiAttachmentPickFailed].
  Future<AiAttachmentPickResult> pick(AiAttachmentIntent intent);
}
