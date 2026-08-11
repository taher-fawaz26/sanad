/// Backend endpoints for the unified contact-verification flow.
abstract final class ContactVerificationApiPaths {
  ContactVerificationApiPaths._();

  /// `POST` — send a code to a new email/phone. Body: `{purpose, target}`.
  static const String request = 'contact-verification/request';

  /// `POST` — resend the code for a live session. Body: `{purpose}`.
  static const String resend = 'contact-verification/resend';

  /// `GET` — cooldown/attempts for a live session. Query: `?purpose=`.
  static const String resendInfo = 'contact-verification/resend-info';

  /// `POST` — verify a code and apply the change. Body: `{purpose, code}`.
  static const String verify = 'contact-verification/verify';
}
