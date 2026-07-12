import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:forgot_password/src/di/forgot_password_di.dart';
import 'package:forgot_password/src/models/create_new_password_args.dart';
import 'package:forgot_password/src/presentation/pages/create_new_password_page.dart';
import 'package:forgot_password/src/presentation/pages/forgot_password_page.dart';
import 'package:forgot_password/src/routes/forgot_password_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:otp/otp.dart';

/// Forgot password feature module — DI and routes.
class ForgotPasswordModule extends FeatureModule {
  @override
  String get name => 'forgot_password';

  @override
  String get version => '0.1.0';

  @override
  List<String> get dependencies => const ['auth', 'otp'];

  @override
  void registerDependencies() => ForgotPasswordDI.init();

  @override
  List<RouteBase> routes(FeatureRouteContext ctx) => [
        GoRoute(
          path: ForgotPasswordRoutes.forgotPassword,
          builder: (context, state) => ForgotPasswordPage(
            onBackToLogin: () => context.go(AuthRoutes.login),
            onOtpSent: (args) => context.push(OtpRoutes.otp, extra: args),
          ),
        ),
        GoRoute(
          path: ForgotPasswordRoutes.resetPassword,
          redirect: (context, state) => state.extra is CreateNewPasswordArgs
              ? null
              : AuthRoutes.login,
          builder: (context, state) {
            final args = state.extra! as CreateNewPasswordArgs;
            return CreateNewPasswordPage(
              args: args,
              onSuccess: () => context.go(AuthRoutes.login),
            );
          },
        ),
      ];
}
