import 'package:account_settings/account_settings.dart';
import 'package:auth/auth.dart';
import 'package:authorization/authorization.dart';
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
import 'package:sanad_provider/src/routing/provider_route_permissions.dart';
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

  final authorizationReader = sl<AuthorizationReader>();

  return GoRouter(
    navigatorKey: providerRootNavigatorKey,
    initialLocation: AuthRoutes.splash,
    // Permission changes (e.g. the post-splash /me resync, or an app-resume
    // resync) must re-run the redirect the same way an auth-status change
    // does — AuthorizationReader notifies only on a genuine decision change,
    // so this does not introduce redirect churn. See ProviderRoutePermissions
    // for the real (Branches/Services/Workers) rules the table holds today.
    refreshListenable: Listenable.merge([authStatus, authorizationReader]),
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
        isProviderOwner: sl<SessionManager>().isProviderOwner,
        isOrganizationTeamMember: sl<SessionManager>().isOrganizationTeamMember,
        permissions: authorizationReader.permissions,
        permissionsResolved: authorizationReader.isResolved,
        table: providerRoutePermissions,
        // Backed by `service-provider/legal-data`, owner-only (RBAC Phase
        // 7G) — unreachable via today's UI for a non-owner (the Compliance
        // Documents section renders no entries when the fetch 403s, so its
        // "Update Document" action never appears), but guarded here too in
        // case of a future deep link or UI change, matching the "deep links
        // guarded" bar the rest of Phase 7 holds every owner-only route to.
        ownerOnlyRoutes: const {OrganizationSettingsRoutes.legalDocuments},
      );
    },
    routes: [
      AuthShell.buildShellRoute(
        children: [
          ...moduleRoutes,
          // Contributed here, not via the generic `moduleRegistry` route
          // list — `WorkersModule.route` needs an `isOwner` callback (RBAC
          // Phase 7F) that `FeatureModule.routes(ctx)`'s signature has no
          // way to carry. Same reasoning as `ServicesModule.shellRoute`.
          WorkersModule.route(
            isOwner: () => sl<SessionManager>().isProviderOwner,
          ),
          // `BranchesModule.ownerAwareRoutes` needs the same `isOwner`
          // callback, to gate the persona-controlled Delete swipe/action
          // (RBAC backend gap G2 — no delete permission exists).
          ...BranchesModule.ownerAwareRoutes(
            isOwner: () => sl<SessionManager>().isProviderOwner,
          ),
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
                routes: [
                  ServicesModule.shellRoute(
                    isOwner: () => sl<SessionManager>().isProviderOwner,
                  ),
                ],
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
      GoRoute(
        path: AppRoutes.forbidden,
        builder: (context, state) => AppForbiddenPage(
          title: 'common.forbidden_title'.tr(),
          description: 'common.forbidden_description'.tr(),
          homeLabel: 'common.forbidden_home'.tr(),
          onGoHome: () => context.go(AppRoutes.home),
        ),
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
/// auth-guard, organization-only-route, and permission-route rules are
/// unit-testable without standing up GoRouter/DI.
///
/// [location] must already be [GoRouterState.matchedLocation]; the splash
/// route is handled by the caller before this is invoked.
///
/// [permissions]/[permissionsResolved]/[table] all default to values that
/// make this function behave identically to its pre-authorization shape —
/// an empty [table] never redirects, so every existing call site (and every
/// test written before permission-aware routing existed) is unaffected.
///
/// [ownerOnlyRoutes] is an explicit, caller-supplied exact-match set — the
/// real call site passes one entry (RBAC Phase 7G). [isProviderOwner] is not
/// limited to that one entry, though: the owner-only guard itself also
/// consults each feature's own `isOwnerOnlyRoute`/`isProtectedRoute`
/// predicate (RBAC Phase 7E) — see the guard's own comment for the current
/// route list.
///
/// [isOrganizationTeamMember] defaults to `false`, which reproduces the
/// pre-Phase-7E behaviour for every existing caller (individual providers and
/// organization owners) — it only changes the outcome for worker/manager
/// accounts hitting an organization-only route, letting them fall through to
/// the permission guard below instead of being redirected on persona alone.
String? resolveProviderRedirect({
  required String location,
  required bool isAuthenticated,
  required bool canManageOrganization,
  bool isProviderOwner = false,
  bool isOrganizationTeamMember = false,
  PermissionSet permissions = PermissionSet.empty,
  bool permissionsResolved = false,
  RouteAuthorizationTable table = RouteAuthorizationTable.empty,
  Set<String> ownerOnlyRoutes = const {},
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
  //
  // `!canManageOrganization` alone is NOT enough here (RBAC Phase 7E fix): it
  // is `isCompany`, true only for the organization *owner*. A worker or
  // manager's own `userType` is never `organizationProvider`, so without the
  // `isOrganizationTeamMember` escape hatch this guard would redirect every
  // team member to the Settings hub before the permission guard below ever
  // ran — silently defeating Branches' permission-gated access for workers.
  final isOrgOnlyRoute =
      BranchRoutes.isProtectedRoute(location) ||
      WorkerRoutes.isProtectedRoute(location) ||
      ProviderRbacRoutes.isProtectedRoute(location);
  if (isOrgOnlyRoute &&
      isAuthenticated &&
      !canManageOrganization &&
      !isOrganizationTeamMember) {
    return OrganizationSettingsRoutes.hub;
  }

  // Settings-tab persona redirect (RBAC Phase 7K).
  //
  // `/settings`'s route builder chooses between the org KPI hub (for
  // canManageOrganization) and GeneralSettingsPage. That default path
  // mounts `OrganizationSettingsBloc`, which triggers three owner-only
  // backend surfaces via its repository (`service-provider/completion`,
  // `service-provider/working-hours`, and — chained inside `_fetchLegalData
  // OrNull` — `service-provider/legal-data`). Phase 7G gated the first two
  // in the bloc; 7K gates the third in the repo; but even with all three
  // gated the *page* still misleads a worker into thinking these are their
  // settings surfaces. The correct behaviour is: a non-owner sees only
  // Account Settings — never General Settings and never the KPI hub.
  //
  // The Settings bottom-nav tap (which opens the popover menu) is separately
  // gated in `showSettingsMenuSheet`; this redirect covers the deep-link and
  // direct-URL cases where someone reaches `/settings` without going through
  // the menu.
  if (location == OrganizationSettingsRoutes.hub &&
      isAuthenticated &&
      !isProviderOwner) {
    return AccountSettingsRoutes.hub;
  }

  // Owner-only surfaces: the backend defines no permission for these at all
  // (RBAC Phase 7 finding F1) — worker/manager tokens 403 regardless of
  // their granted permissions, so a persona check is the only correct client
  // gate. Deliberately isProviderOwner (individual OR organization), not
  // canManageOrganization/isCompany — an individual provider owner is
  // authorized for these surfaces too (finding F2).
  //
  // [ownerOnlyRoutes] itself is an explicit, caller-supplied set of exact
  // paths — the real call site below passes exactly one entry today
  // (`OrganizationSettingsRoutes.legalDocuments`, RBAC Phase 7G). The
  // feature-declared predicates ORed in below (RBAC Phase 7E) cover the
  // routes that need owner-only gating via pattern/prefix matching instead
  // of a literal path: all of provider RBAC (administration is owner-only in
  // its entirety — finding F1), and the owner-only sub-surfaces within
  // Workers and Services (inviting/editing a worker, adding a service,
  // requesting a new catalog service, viewing a service request — RBAC
  // Phase 7 finding G3: no permission exists for any of these writes).
  // Each feature's `list`/`details` are deliberately excluded from its
  // predicate — those stay permission-gated below instead.
  final isOwnerOnlyRoute =
      ownerOnlyRoutes.contains(location) ||
      ProviderRbacRoutes.isProtectedRoute(location) ||
      WorkerRoutes.isOwnerOnlyRoute(location) ||
      ServiceRoutes.isOwnerOnlyRoute(location);
  if (isOwnerOnlyRoute && isAuthenticated && !isProviderOwner) {
    return AppRoutes.home;
  }

  // Permission guard — runs last, after auth/persona have already cleared
  // the request. Fails OPEN on an unresolved snapshot (deep links and a
  // just-restored cold start must never be bounced on a timing artifact —
  // see PermissionResync and AuthorizationReader.isResolved) and only denies
  // a route the snapshot has positively confirmed the user lacks.
  if (!isAuthenticated || !permissionsResolved) return null;
  final rule = table.ruleFor(location);
  if (rule != null && !rule.requires.isSatisfiedBy(permissions)) {
    return rule.denyRedirect ?? AppRoutes.home;
  }

  return null;
}
