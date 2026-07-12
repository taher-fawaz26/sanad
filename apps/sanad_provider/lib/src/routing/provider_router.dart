import 'package:auth/auth.dart';
import 'package:branches/branches.dart';
import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forgot_password/forgot_password.dart';
import 'package:go_router/go_router.dart';
import 'package:otp/otp.dart';
import 'package:sanad_provider/src/di/app_di.dart';
import 'package:sanad_provider/src/features/home/home_page.dart';
import 'package:sanad_provider/src/features/messages/messages_page.dart';
import 'package:sanad_provider/src/features/requests/requests_page.dart';
import 'package:sanad_provider/src/features/settings/settings_page.dart';
import 'package:sanad_provider/src/routing/app_routes.dart';
import 'package:sanad_provider/src/routing/shell/main_shell.dart';

/// sanad_provider top-level router, independent from sanad_client.
GoRouter buildProviderRouter() {
  final authStatus = sl<AuthStatusNotifier>();
  final routeContext = FeatureRouteContext(
    homeRoute: AppRoutes.home,
    userType: FeatureUserType.provider,
    protectedRoutes: {
      ...AppRoutes.protected,
      ...BranchRoutes.protectedRoutes,
    },
    onRegisteredNeedsVerification: (context, identifier, isPhoneIdentifier) {
      context.push(
        OtpRoutes.otp,
        extra: OtpArgs(
          identifier: identifier,
          type: isPhoneIdentifier ? IdentifierType.phone : IdentifierType.email,
        ),
      );
    },
  );

  return GoRouter(
    initialLocation: AuthRoutes.splash,
    refreshListenable: authStatus,
    redirect: (context, state) {
      if (state.matchedLocation == AuthRoutes.splash) return null;

      final isProtected = routeContext.protectedRoutes.contains(
        state.matchedLocation,
      );
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
          ...moduleRegistry.allRoutes(routeContext),
          // Combined OTP route — shared by verification and forgot-password flows.
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
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) =>
                MainShell(navigationShell: navigationShell),
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppRoutes.home,
                    builder: (context, state) => const ProviderHomePage(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppRoutes.requests,
                    builder: (context, state) => const RequestsPage(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppRoutes.messages,
                    builder: (context, state) => const ProviderMessagesPage(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppRoutes.settings,
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
