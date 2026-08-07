import 'package:auth/auth.dart';
import 'package:branches/branches.dart';
import 'package:core/core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:network/network.dart';
import 'package:organization_settings/organization_settings.dart';
import 'package:registration/registration.dart';
import 'package:sanad_provider/src/di/app_di.dart';
import 'package:sanad_provider/src/features/home/home_page.dart';
import 'package:sanad_provider/src/features/messages/messages_page.dart';
import 'package:sanad_provider/src/features/requests/requests_page.dart';
import 'package:sanad_provider/src/features/services/services_page.dart';
import 'package:sanad_provider/src/routing/app_routes.dart';
import 'package:sanad_provider/src/routing/provider_navigator.dart';
import 'package:sanad_provider/src/routing/shell/main_shell.dart';
import 'package:shared_ui/shared_ui.dart';

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
  );

  // Module-contributed routes, with the auth-provided `/login` route swapped
  // for an app-owned one whose "Sign up" link opens the registration flow.
  final moduleRoutes = [
    for (final route in moduleRegistry.allRoutes(routeContext))
      if (route is GoRoute && route.path == AuthRoutes.login)
        GoRoute(
          path: AuthRoutes.login,
          builder: (context, state) => AuthPage(
            onOtpSent: (email) => context.push(AuthRoutes.otp, extra: email),
            onAuthenticated: () => context.go(AppRoutes.home),
            onOnboarding: (email, token) => context.go(
              RegistrationRoutes.selectAccountType,
              extra: OnboardingArgs(
                email: email,
                onboardingToken: token,
              ),
            ),
          ),
        )
      else
        route,
  ];

  return GoRouter(
    navigatorKey: providerRootNavigatorKey,
    initialLocation: AuthRoutes.splash,
    refreshListenable: authStatus,
    errorBuilder: (context, state) => AppNotFoundPage(
      title: 'common.not_found_title'.tr(),
      description: 'common.not_found_description'.tr(),
      homeLabel: 'common.not_found_home'.tr(),
      onGoHome: () => context.go(AppRoutes.home),
    ),
    redirect: (context, state) {
      if (state.matchedLocation == AuthRoutes.splash) return null;

      final isProtected =
          AppRoutes.protected.contains(state.matchedLocation) ||
          BranchRoutes.isProtectedRoute(state.matchedLocation);
      if (isProtected && authStatus.status != AuthStatus.authenticated) {
        return AuthRoutes.login;
      }
      return null;
    },
    routes: [
      AuthShell.buildShellRoute(
        children: [
          ...moduleRoutes,
          AuthShell.otpRoute(
            onAuthenticated: (context) => context.go(AppRoutes.home),
            onOnboarding: (context, email, onboardingToken) => context.go(
              RegistrationRoutes.selectAccountType,
              extra: OnboardingArgs(
                email: email,
                onboardingToken: onboardingToken,
              ),
            ),
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
                    path: AppRoutes.messages,
                    builder: (context, state) => const ProviderMessagesPage(),
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
                    path: AppRoutes.services,
                    builder: (context, state) => const ProviderServicesPage(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppRoutes.settings,
                    builder: (context, state) =>
                        const OrganizationSettingsPage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.offline,
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
