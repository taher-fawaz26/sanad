import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forgot_password/forgot_password.dart';
import 'package:go_router/go_router.dart';
import 'package:network/network.dart';
import 'package:otp/otp.dart';
import 'package:sanad_client/src/di/app_di.dart';
import 'package:sanad_client/src/features/home/home_page.dart';

const _clientHome = '/home';
const _clientOffline = '/offline';

/// sanad_client top-level router, independent from sanad_provider.
GoRouter buildClientRouter() {
  final authStatus = sl<AuthStatusNotifier>();
  final routeContext = FeatureRouteContext(
    homeRoute: _clientHome,
    userType: FeatureUserType.client,
    protectedRoutes: {_clientHome},
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

      final isProtected = routeContext.protectedRoutes
          .contains(state.matchedLocation);
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
        ],
      ),
      GoRoute(
        path: _clientHome,
        builder: (context, state) => const ClientHomePage(),
      ),
      GoRoute(
        path: _clientOffline,
        builder: (context, state) {
          final navTitle = state.extra is String ? state.extra! as String : '';
          return AppNetworkErrorPage(
            navTitle: navTitle,
            title: 'empty_states.network_title'.tr(),
            description: 'empty_states.network_description'.tr(),
            retryLabel: 'empty_states.retry'.tr(),
            onBack: () => context.pop(),
            onRetry: () async {
              final online = await sl<ConnectivityController>().check();
              if (online && context.mounted) context.pop();
            },
          );
        },
      ),
    ],
  );
}
