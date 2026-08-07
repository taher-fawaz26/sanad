import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:network/network.dart';
import 'package:sanad_client/src/di/app_di.dart';
import 'package:sanad_client/src/features/home/home_page.dart';
import 'package:sanad_client/src/routing/client_routes.dart';
import 'package:shared_ui/shared_ui.dart';

/// sanad_client top-level router, independent from sanad_provider.
GoRouter buildClientRouter() {
  final authStatus = sl<AuthStatusNotifier>();
  final routeContext = FeatureRouteContext(
    homeRoute: ClientRoutes.home,
    protectedRoutes: ClientRoutes.protected,
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
          AuthShell.otpRoute(
            // The client app has no onboarding flow; a brand-new account
            // returns to login (sign-up lives in the provider app).
            onAuthenticated: (context) => context.go(ClientRoutes.home),
            onOnboarding: (context, email, onboardingToken) =>
                context.go(AuthRoutes.login),
          ),
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
