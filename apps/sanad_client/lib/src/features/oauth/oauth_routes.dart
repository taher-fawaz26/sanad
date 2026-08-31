/// Route path constants for the client's pre-auth OAuth flow (Splash, OAuth
/// screen, Email screen).
///
/// [splash] intentionally reuses the same path value as `AuthRoutes.splash`
/// (`'/'`) — `client_router.dart` mounts this app's own [OAuthRoutes] pages
/// at that path instead of `packages/auth`'s shared `SplashPage`, so
/// `GoRouter.initialLocation` (which still points at `AuthRoutes.splash`)
/// keeps working unchanged. See `client_router.dart` for the route-filtering
/// that makes this override safe.
abstract final class OAuthRoutes {
  OAuthRoutes._();

  /// OAuth splash — auto-navigates to [screen].
  static const splash = '/';

  /// OAuth screen — the authentication-method entry point (UAE PASS, Email,
  /// Google, Phone).
  static const screen = '/oauth';

  /// Continue with Email form.
  static const email = '/oauth/email';

  /// Continue with Phone form.
  static const phone = '/oauth/phone';

  /// Continue in UAE PASS.
  static const uaePass = '/oauth/uae-pass';

  /// Waiting for UAE PASS — reached after tapping "Open UAE PASS" on
  /// [uaePass].
  static const uaePassWaiting = '/oauth/uae-pass/waiting';

  /// We collect data from UAE PASS.
  static const uaePassCollecting = '/oauth/uae-pass/collecting';

  /// You're all set! — the final screen of the UAE PASS flow. Accepts an
  /// optional `UaePassCollectedDetails` via route `extra`.
  static const uaePassSuccess = '/oauth/uae-pass/success';

  /// Shared OTP screen, reached from [email] or [phone]. Configured per
  /// visit via the `OAuthOtpRouteArgs` route `extra` — see
  /// `client_router.dart`'s registration of this path.
  static const otp = '/oauth/otp';
}
