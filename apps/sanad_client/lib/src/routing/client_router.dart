import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:network/network.dart';
import 'package:sanad_client/src/di/app_di.dart';
import 'package:sanad_client/src/features/home/home_page.dart';
import 'package:sanad_client/src/features/onboarding/continue_with_email_page.dart';
import 'package:sanad_client/src/features/onboarding/get_started_page.dart';
import 'package:sanad_client/src/features/onboarding/onboarding_routes.dart';
import 'package:sanad_client/src/features/onboarding/splash_page.dart';
import 'package:sanad_client/src/routing/client_routes.dart';
import 'package:shared_ui/shared_ui.dart';

/// sanad_client top-level router, independent from sanad_provider.
GoRouter buildClientRouter() {
  final authStatus = sl<AuthStatusNotifier>();
  const routeContext = FeatureRouteContext(
    homeRoute: ClientRoutes.home,
    protectedRoutes: ClientRoutes.protected,
  );

  // AuthModule unconditionally registers '/' (packages/auth's SplashPage)
  // and '/login' (its combined AuthPage) — the client app renders its own
  // onboarding flow (OnboardingSplashPage / GetStartedPage /
  // ContinueWithEmailPage) at those paths instead. packages/auth stays
  // unmodified (sanad_provider still uses its screens as-is; this app still
  // needs AuthModule for AuthBloc/session/OTP). Do not remove this filter:
  // without it GoRouter throws GoError('Duplicate path') at startup.
  const authOverriddenPaths = {AuthRoutes.splash, AuthRoutes.login};
  final moduleRoutes = moduleRegistry.allRoutes(routeContext);
  final filteredModuleRoutes = moduleRoutes
      .where(
        (route) =>
            route is! GoRoute || !authOverriddenPaths.contains(route.path),
      )
      .toList();

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
          GoRoute(
            path: OnboardingRoutes.splash,
            builder: (context, state) => const OnboardingSplashPage(),
          ),
          GoRoute(
            path: OnboardingRoutes.getStarted,
            builder: (context, state) => const GetStartedPage(),
          ),
          GoRoute(
            path: OnboardingRoutes.continueWithEmail,
            builder: (context, state) => const ContinueWithEmailPage(),
          ),
          ...filteredModuleRoutes,
          AuthShell.otpRoute(
            // No post-signup onboarding token flow for the client app yet
            // (unrelated to the pre-auth features/onboarding screens above);
            // a brand-new account returns to login (sign-up lives in the
            // provider app).
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
            retryLabel: 'common.retry'.tr(),
            onBack: () => context.pop(),
            onRetry: () async {
              final online = await sl<ConnectivityController>().check();
              if (online && context.mounted) context.pop();
            },
          );
        },
      ),
      GoRoute(
        path: ClientRoutes.forbidden,
        builder: (context, state) => AppForbiddenPage(
          title: 'common.forbidden_title'.tr(),
          description: 'common.forbidden_description'.tr(),
          homeLabel: 'common.forbidden_home'.tr(),
          onGoHome: () => context.go(ClientRoutes.home),
        ),
      ),
    ],
  );
}
