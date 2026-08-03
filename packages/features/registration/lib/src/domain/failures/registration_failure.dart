/// Typed failures that the registration cubit can emit.
///
/// Consumers pattern-match on the concrete type to decide how to render:
///   - [UploadFailure]     → snackbar on the upload step pages
///   - [ExtractionFailure] → drives the retry UI on the extracting page
///   - [ProfileFailure]    → drives the retry dialog on the review page
sealed class RegistrationFailure {
  const RegistrationFailure({required this.messageKey});

  /// A localisation key (or server prose) describing what went wrong.
  final String messageKey;
}

/// Document upload failed.
final class UploadFailure extends RegistrationFailure {
  const UploadFailure({required super.messageKey});
}

/// Document extraction (OCR) failed.
final class ExtractionFailure extends RegistrationFailure {
  const ExtractionFailure({required super.messageKey, required this.kind});

  final ExtractionFailureKind kind;
}

/// Why extraction failed — lets the UI route to retry vs re-scan vs support.
enum ExtractionFailureKind {
  /// Token or required upload IDs were missing before the request was sent.
  missingToken,

  /// Connectivity or timeout error.
  network,

  /// Server returned a non-409 error.
  server,
}

/// Profile completion API call failed.
final class ProfileFailure extends RegistrationFailure {
  const ProfileFailure({required super.messageKey});
}
