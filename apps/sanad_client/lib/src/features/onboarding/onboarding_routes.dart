/// Route path constants for the client's pre-auth onboarding flow (Splash,
/// Get Started, Continue with Email).
///
/// [splash] intentionally reuses the same path value as `AuthRoutes.splash`
/// (`'/'`) — `client_router.dart` mounts this app's own [OnboardingRoutes]
/// pages at that path instead of `packages/auth`'s shared `SplashPage`, so
/// `GoRouter.initialLocation` (which still points at `AuthRoutes.splash`)
/// keeps working unchanged. See `client_router.dart` for the route-filtering
/// that makes this override safe.
abstract final class OnboardingRoutes {
  OnboardingRoutes._();

  /// Onboarding splash — auto-navigates to [getStarted].
  static const splash = '/';

  /// Get Started / login-method chooser.
  static const getStarted = '/get-started';

  /// Continue with Email form.
  static const continueWithEmail = '/get-started/email';
}
