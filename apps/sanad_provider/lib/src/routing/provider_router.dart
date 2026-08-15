import 'package:auth/auth.dart';
import 'package:branches/branches.dart';
import 'package:core/core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:network/network.dart';
import 'package:provider_rbac/provider_rbac.dart';
import 'package:sanad_provider/src/features/organization_settings/organization_settings.dart';
import 'package:sanad_provider/src/features/registration/registration.dart';
import 'package:sanad_provider/src/di/app_di.dart';
import 'package:sanad_provider/src/features/home/home_page.dart';
import 'package:sanad_provider/src/features/messages/messages_page.dart';
import 'package:sanad_provider/src/features/requests/requests_page.dart';
import 'package:sanad_provider/src/routing/app_routes.dart';
import 'package:sanad_provider/src/routing/provider_capabilities.dart';
import 'package:sanad_provider/src/routing/provider_navigator.dart';
import 'package:sanad_provider/src/routing/shell/main_shell.dart';
import 'package:services/services.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:workers/workers.dart';

/// sanad_provider top-level router, independent from sanad_client.
GoRouter buildProviderRouter() {
  final authStatus = sl<AuthStatusNotifier>();
  final routeContext = FeatureRouteContext(
    homeRoute: AppRoutes.home,
    userType: FeatureUserType.provider,
    protectedRoutes: {
      ...AppRoutes.protected,
      ...BranchRoutes.protectedRoutes,
      ...WorkerRoutes.protectedRoutes,
      ...ProviderRbacRoutes.protectedRoutes,
      ...ServiceRoutes.protectedRoutes,
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
            onOtpSent: (email, intent) => context.push(
              AuthRoutes.otp,
              extra: AuthOtpRouteArgs(email: email, intent: intent),
            ),
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
      return resolveProviderRedirect(
        location: state.matchedLocation,
        isAuthenticated: authStatus.status == AuthStatus.authenticated,
        canManageOrganization: sl<SessionManager>().canManageOrganization,
      );
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
                // `ServicesModule` no longer contributes `/services` as a
                // top-level route (it used to shadow this branch on first
                // tab visit, hiding the bottom nav bar) — the full route
                // tree, including bloc wiring, lives in
                // `ServicesModule.shellRoute()`.
                routes: [ServicesModule.shellRoute()],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppRoutes.settings,
                    builder: (context, state) => buildSettingsTabPage(
                      canManageOrganization:
                          context.session.canManageOrganization,
                    ),
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
            retryLabel: 'common.retry'.tr(),
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

/// The page mounted by the shell Settings tab ([AppRoutes.settings]) for the
/// given persona — extracted from the route builder so the persona split is
/// unit-testable without standing up GoRouter/DI.
///
/// Organization providers ([canManageOrganization] == true) land on the
/// KPI/setup hub, which pushes General Settings as a child route (with a back
/// button). Individual providers have no organization hub, so General Settings
/// IS their primary Settings tab: mounted here as a root destination
/// ([GeneralSettingsPage.isRootTab] == true) with the bottom nav visible and no
/// back affordance — there is nothing to pop back to.
Widget buildSettingsTabPage({required bool canManageOrganization}) =>
    canManageOrganization
    ? const OrganizationSettingsPage()
    : const GeneralSettingsPage(isRootTab: true);

/// Pure redirect decision for [buildProviderRouter] — extracted so the
/// auth-guard and organization-only-route rules are unit-testable without
/// standing up GoRouter/DI.
///
/// [location] must already be [GoRouterState.matchedLocation]; the splash
/// route is handled by the caller before this is invoked.
String? resolveProviderRedirect({
  required String location,
  required bool isAuthenticated,
  required bool canManageOrganization,
}) {
  final isProtected =
      AppRoutes.protected.contains(location) ||
      BranchRoutes.isProtectedRoute(location) ||
      WorkerRoutes.isProtectedRoute(location) ||
      ProviderRbacRoutes.isProtectedRoute(location) ||
      ServiceRoutes.isProtectedRoute(location);
  if (isProtected && !isAuthenticated) {
    return AuthRoutes.login;
  }

  // Organization-only surfaces: branches, workers/team (+invitations), and
  // provider RBAC. The Settings hub itself (`/settings`) is NOT listed here:
  // it is the shell Settings tab, and its route builder already renders the
  // persona-appropriate page (KPI hub for organizations, General Settings for
  // individuals). Individual providers hitting an org-only surface are sent to
  // their Settings tab — which keeps the bottom nav visible — rather than the
  // full-screen `/settings/general` child (which has no parent to pop back to).
  final isOrgOnlyRoute =
      BranchRoutes.isProtectedRoute(location) ||
      WorkerRoutes.isProtectedRoute(location) ||
      ProviderRbacRoutes.isProtectedRoute(location);
  if (isOrgOnlyRoute && isAuthenticated && !canManageOrganization) {
    return OrganizationSettingsRoutes.hub;
  }

  return null;
}
