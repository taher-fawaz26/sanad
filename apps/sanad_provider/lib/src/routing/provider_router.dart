import 'package:auth/auth.dart';
import 'package:branches/branches.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:forgot_password/forgot_password.dart';
import 'package:go_router/go_router.dart';
import 'package:network/network.dart';
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
    errorBuilder: (context, state) => AppNotFoundPage(
      title: 'common.not_found_title'.tr(),
      description: 'common.not_found_description'.tr(),
      homeLabel: 'common.not_found_home'.tr(),
      onGoHome: () => context.go(AppRoutes.home),
    ),
    redirect: (context, state) {
      if (state.matchedLocation == AuthRoutes.splash) return null;

      final isProtected = BranchRoutes.isProtectedRoute(
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
