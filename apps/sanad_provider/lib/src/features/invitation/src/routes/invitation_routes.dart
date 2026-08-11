/// Route constants for the worker-invitation acceptance flow.
///
/// `details` is parameterized by `:token` so it can eventually be reached
/// directly from an OS-level deep link (`https://.../invitation/{token}` or
/// a custom scheme) once that wiring lands — see `InvitationModule`'s doc
/// comment for what's still missing. Until then, callers navigate here with
/// `context.push(InvitationRoutes.detailsPath(token))`.
abstract final class InvitationRoutes {
  InvitationRoutes._();

  static const String details = '/invitation/:token';
  static const String otp = '/invitation/otp';
  static const String success = '/invitation/success';

  /// Builds a concrete `details` path for a given invitation [token].
  static String detailsPath(String token) => '/invitation/$token';
}
