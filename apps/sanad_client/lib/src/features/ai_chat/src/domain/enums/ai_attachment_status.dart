/// Where an attachment is in its journey from "the user picked it" to "it is
/// part of a sent message".
///
/// Deliberately explicit rather than a pair of booleans: the composer needs to
/// tell "still being prepared" from "ready to send" from "failed, offer retry",
/// and a widget must never have to infer that from a null check.
enum AiAttachmentStatus {
  /// Acquired from the picker, nothing checked yet.
  picked,

  /// Being checked against the type/size/count rules.
  validating,

  /// Passed validation; a thumbnail or duration is being derived.
  processing,

  /// Fully prepared. Only a [ready] attachment may be sent.
  ready,

  /// Rejected or broken. Carries a localization key explaining why.
  failed,

  /// Attached to a message that has left the composer.
  sent
  ;

  /// Whether this attachment may be included in a submitted message.
  bool get isReady => this == AiAttachmentStatus.ready;

  /// Whether the composer should still show a spinner over it.
  bool get isBusy =>
      this == AiAttachmentStatus.picked ||
      this == AiAttachmentStatus.validating ||
      this == AiAttachmentStatus.processing;

  /// Whether a retry affordance makes sense.
  bool get isFailed => this == AiAttachmentStatus.failed;
}
