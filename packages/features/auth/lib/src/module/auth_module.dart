import 'package:auth/src/di/auth_di.dart';
import 'package:auth/src/domain/enums/user_type.dart';
import 'package:auth/src/presentation/pages/login_page.dart';
import 'package:auth/src/presentation/pages/register_page.dart';
import 'package:auth/src/presentation/pages/splash_page.dart';
import 'package:auth/src/routes/auth_routes.dart';
import 'package:core/core.dart';
import 'package:go_router/go_router.dart';

/// Auth feature module — DI and routes.
class AuthModule extends FeatureModule {
  /// Forgot-password path constant — avoids circular package dependency.
  static const forgotPasswordPath = '/forgot-password';

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
    final userType = ctx.userType == FeatureUserType.provider
        ? UserType.provider
        : UserType.client;
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
          onAuthenticated: () => context.go(home),
          onForgotPassword: () => context.push(forgotPasswordPath),
          onRegister: () => context.push(AuthRoutes.register),
        ),
      ),
      GoRoute(
        path: AuthRoutes.register,
        builder: (context, state) => RegisterPage(
          userType: userType,
          onSignIn: () => context.go(AuthRoutes.login),
          onRegistered: (identifier, mode) {
            ctx.onRegisteredNeedsVerification?.call(
              context,
              identifier,
              mode == RegisterIdentifierMode.phone,
            );
          },
        ),
      ),
    ];
  }
}
