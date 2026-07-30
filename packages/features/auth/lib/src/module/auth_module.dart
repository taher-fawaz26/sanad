import 'package:auth/src/di/auth_di.dart';
import 'package:auth/src/presentation/pages/login_page.dart';
import 'package:auth/src/presentation/pages/splash_page.dart';
import 'package:auth/src/routes/auth_routes.dart';
import 'package:core/core.dart';
import 'package:go_router/go_router.dart';

/// Auth feature module — DI and routes.
///
/// Contributes the splash and (email-only) login routes. The shared OTP route
/// is composed by each app via `AuthShell.otpRoute` so the app can wire its own
/// post-verification navigation (dashboard vs onboarding).
class AuthModule extends FeatureModule {
  @override
  String get name => 'auth';

  @override
  String get version => '0.1.0';

  @override
  List<String> get dependencies => const [];

  @override
  void registerDependencies() => AuthDI.init();

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
        builder: (context, state) => LoginPage(
          onOtpSent: (email) => context.push(AuthRoutes.otp, extra: email),
        ),
      ),
    ];
  }
}
