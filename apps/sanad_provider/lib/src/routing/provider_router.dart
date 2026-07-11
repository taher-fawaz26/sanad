import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forgot_password/forgot_password.dart';
import 'package:go_router/go_router.dart';
import 'package:otp/otp.dart';
import 'package:sanad_provider/src/features/home/home_page.dart';
import 'package:sanad_provider/src/features/messages/messages_page.dart';
import 'package:sanad_provider/src/features/requests/requests_page.dart';
import 'package:sanad_provider/src/features/settings/settings_page.dart';
import 'package:sanad_provider/src/routing/shell/main_shell.dart';

/// Routes that require authentication. Any navigation into one of these
/// while unauthenticated is redirected to the login screen.
const _protectedRoutes = <String>{
  _providerHome,
  _providerRequests,
  _providerMessages,
  _providerSettings,
};

/// sanad_provider top-level router, independent from sanad_client.
GoRouter buildProviderRouter() {
  final authStatus = sl<AuthStatusNotifier>();
  return GoRouter(
    initialLocation: AuthRoutes.splash,
    refreshListenable: authStatus,
    redirect: (context, state) {
      // Splash screen decides its own destination; never redirect.
      if (state.matchedLocation == AuthRoutes.splash) return null;

      final isProtected = _protectedRoutes.contains(state.matchedLocation);
      if (isProtected && authStatus.status != AuthStatus.authenticated) {
        return AuthRoutes.login;
      }
      return null;
    },
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
              onAuthenticated: () => context.go(_providerHome),
              onUnauthenticated: () => context.go(AuthRoutes.login),
            ),
          ),
          GoRoute(
            path: AuthRoutes.login,
            builder: (context, state) => LoginPage(
              onAuthenticated: () => context.go(_providerHome),
              onForgotPassword: () =>
                  context.push(ForgotPasswordRoutes.forgotPassword),
              onRegister: () => context.push(AuthRoutes.register),
            ),
          ),
          GoRoute(
            path: AuthRoutes.register,
            builder: (context, state) => RegisterPage(
              userType: UserType.provider,
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
            redirect: (context, state) =>
                state.extra is OtpArgs ? null : AuthRoutes.login,
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
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) =>
                MainShell(navigationShell: navigationShell),
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: _providerHome,
                    builder: (context, state) => const ProviderHomePage(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: _providerRequests,
                    builder: (context, state) => const ProviderRequestsPage(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: _providerMessages,
                    builder: (context, state) => const ProviderMessagesPage(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: _providerSettings,
                    builder: (context, state) => const ProviderSettingsPage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

const _providerHome = '/home';
const _providerRequests = '/requests';
const _providerMessages = '/messages';
const _providerSettings = '/settings';
