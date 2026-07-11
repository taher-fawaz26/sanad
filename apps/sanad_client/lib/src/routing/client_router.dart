import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forgot_password/forgot_password.dart';
import 'package:go_router/go_router.dart';
import 'package:otp/otp.dart';
import 'package:sanad_client/src/features/home/home_page.dart';

/// sanad_client top-level router, independent from sanad_provider.
GoRouter buildClientRouter() {
  return GoRouter(
    initialLocation: AuthRoutes.splash,
    routes: [
      ShellRoute(
        builder: (context, state, child) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => sl<AuthBloc>()),
            BlocProvider(create: (_) => sl<OtpBloc>()),
            BlocProvider(create: (_) => sl<ForgotPasswordBloc>()),
          ],
          child: child,
        ),
        routes: [
          GoRoute(
            path: AuthRoutes.splash,
            builder: (context, state) => SplashPage(
              onAuthenticated: () => context.go(_clientHome),
              onUnauthenticated: () => context.go(AuthRoutes.login),
            ),
          ),
          GoRoute(
            path: AuthRoutes.login,
            builder: (context, state) => LoginPage(
              onAuthenticated: () => context.go(_clientHome),
              onForgotPassword: () =>
                  context.push(ForgotPasswordRoutes.forgotPassword),
              onRegister: () => context.push(AuthRoutes.register),
            ),
          ),
          GoRoute(
            path: AuthRoutes.register,
            builder: (context, state) => RegisterPage(
              onSignIn: () => context.go(AuthRoutes.login),
              onRegistered: (identifier, mode) {
                context.push(
                  OtpRoutes.otp,
                  extra: OtpArgs(
                    identifier: identifier,
                    type: mode == RegisterIdentifierMode.email
                        ? IdentifierType.email
                        : IdentifierType.phone,
                  ),
                );
              },
            ),
          ),
          GoRoute(
            path: OtpRoutes.otp,
            builder: (context, state) {
              final args = state.extra! as OtpArgs;
              if (args.flow == OtpFlow.forgotPassword) {
                return ForgotPasswordOtpPage(
                  args: args,
                  onBackToLogin: () => context.go(AuthRoutes.login),
                  onVerified: (identifier) {
                    context.push(
                      ForgotPasswordRoutes.resetPassword,
                      extra: CreateNewPasswordArgs(identifier: identifier),
                    );
                  },
                );
              }
              return VerificationCodePage(
                args: args,
                onVerified: () => context.go(AuthRoutes.login),
                onBackToLogin: () => context.go(AuthRoutes.login),
              );
            },
          ),
          GoRoute(
            path: ForgotPasswordRoutes.forgotPassword,
            builder: (context, state) => ForgotPasswordPage(
              onBackToLogin: () => context.go(AuthRoutes.login),
              onOtpSent: (args) => context.push(OtpRoutes.otp, extra: args),
            ),
          ),
          GoRoute(
            path: ForgotPasswordRoutes.resetPassword,
            builder: (context, state) {
              final args = state.extra! as CreateNewPasswordArgs;
              return CreateNewPasswordPage(
                args: args,
                onSuccess: () => context.go(AuthRoutes.login),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: _clientHome,
        builder: (context, state) => const ClientHomePage(),
      ),
    ],
  );
}

const _clientHome = '/home';
