import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:forgot_password/forgot_password.dart';
import 'package:go_router/go_router.dart';
import 'package:network/network.dart';
import 'package:otp/otp.dart';
import 'package:sanad_client/src/di/app_di.dart';
import 'package:sanad_client/src/features/home/home_page.dart';
import 'package:sanad_client/src/routing/client_routes.dart';

/// sanad_client top-level router, independent from sanad_provider.
GoRouter buildClientRouter() {
  final authStatus = sl<AuthStatusNotifier>();
  final routeContext = FeatureRouteContext(
    homeRoute: ClientRoutes.home,
    protectedRoutes: ClientRoutes.protected,
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
    errorBuilder: (context, state) => AppNotFoundPage(
      title: 'common.not_found_title'.tr(),
      description: 'common.not_found_description'.tr(),
      homeLabel: 'common.not_found_home'.tr(),
      onGoHome: () => context.go(ClientRoutes.home),
    ),
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
      AuthShell.buildShellRoute(
        children: [
          ...moduleRegistry.allRoutes(routeContext),
          AuthShell.combinedOtpRoute(),
        ],
      ),
      GoRoute(
        path: ClientRoutes.home,
        builder: (context, state) => const ClientHomePage(),
      ),
      GoRoute(
        path: ClientRoutes.offline,
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
