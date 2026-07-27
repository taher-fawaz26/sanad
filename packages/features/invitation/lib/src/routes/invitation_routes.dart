/// Route constants for the temporary invitation-flow demo.
///
/// Entry point is exposed from Organization Settings until deep links
/// replace it (see `InvitationModule` doc comment).
abstract final class InvitationRoutes {
  InvitationRoutes._();

  static const String details = '/invitation-demo';
  static const String otp = '/invitation-demo/otp';
  static const String success = '/invitation-demo/success';
}
