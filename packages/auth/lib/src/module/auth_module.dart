import 'package:auth/src/di/auth_di.dart';
import 'package:auth/src/domain/enums/auth_flow_intent.dart';
import 'package:auth/src/presentation/pages/auth_page.dart';
import 'package:auth/src/presentation/pages/scheduled_for_deletion_page.dart';
import 'package:auth/src/presentation/pages/splash_page.dart';
import 'package:auth/src/presentation/pages/suspended_page.dart';
import 'package:auth/src/routes/auth_routes.dart';
import 'package:auth/src/routing/auth_otp_route_args.dart';
import 'package:auth/src/session/session_manager.dart';
import 'package:core/core.dart';
import 'package:go_router/go_router.dart';

/// Auth feature module — DI and routes.
///
/// Contributes the splash, email auth, and suspended routes. The shared OTP
/// route is composed by each app via `AuthShell.otpRoute` so the app can
/// wire its own post-verification navigation (dashboard vs onboarding).
class AuthModule extends FeatureModule {
  /// [onSessionBoundary] — see [AuthDI.init]. Typically
  /// `() => moduleRegistry.disposeAll()`, wired by the app composition root.
  AuthModule({
    void Function()? onSessionBoundary,
    void Function()? onSessionStarted,
    Future<void> Function()? onBeforeSessionEnd,
  }) : _onSessionBoundary = onSessionBoundary,
       _onSessionStarted = onSessionStarted,
       _onBeforeSessionEnd = onBeforeSessionEnd;

  final void Function()? _onSessionBoundary;
  final void Function()? _onSessionStarted;
  final Future<void> Function()? _onBeforeSessionEnd;

  @override
  String get name => 'auth';

  @override
  String get version => '0.1.0';

  @override
  List<String> get dependencies => const [];

  @override
  void registerDependencies() => AuthDI.init(
    onSessionBoundary: _onSessionBoundary,
    onSessionStarted: _onSessionStarted,
    onBeforeSessionEnd: _onBeforeSessionEnd,
  );

  /// Rehydrate the persisted session from Hive so the splash screen can
  /// route the user without re-authenticating. Runs after DI registration
  /// (see [ModuleRegistry.initAll]).
  @override
  Future<void> initialize() async {
    await sl<SessionManager>().restore();
  }

  @override
  List<RouteBase> routes(FeatureRouteContext ctx) {
    final home = ctx.homeRoute;

    return [
      GoRoute(
        path: AuthRoutes.splash,
        builder: (context, state) => SplashPage(
          onAuthenticated: () => context.go(home),
          onUnauthenticated: () => context.go(AuthRoutes.login),
        ),
      ),
      GoRoute(
        path: AuthRoutes.login,
        builder: (context, state) => AuthPage(
          onOtpSent: (email, intent) => context.push(
            AuthRoutes.otp,
            extra: AuthOtpRouteArgs(email: email, intent: intent),
          ),
          onAuthenticated: () => context.go(home),
          onOnboarding: (email, token) => context.push(
            AuthRoutes.otp,
            extra: AuthOtpRouteArgs(
              email: email,
              intent: AuthFlowIntent.createAccount,
            ),
          ),
        ),
      ),
      GoRoute(
        path: AuthRoutes.suspended,
        builder: (context, state) => SuspendedPage(
          onLoggedOut: () => context.go(AuthRoutes.login),
        ),
      ),
      GoRoute(
        path: AuthRoutes.scheduledForDeletion,
        builder: (context, state) => ScheduledForDeletionPage(
          onLoggedOut: () => context.go(AuthRoutes.login),
        ),
      ),
    ];
  }
}
