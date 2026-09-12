import 'package:account_settings/account_settings.dart';
import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:network/network.dart';
import 'package:sanad_client/src/config/app_config.dart';
import 'package:sanad_client/src/di/app_di.dart';
import 'package:sanad_client/src/features/account_setup/account_setup_cubit.dart';
import 'package:sanad_client/src/features/account_setup/account_setup_routes.dart';
import 'package:sanad_client/src/features/account_setup/enter_name_page.dart';
import 'package:sanad_client/src/features/account_setup/get_notified_page.dart';
import 'package:sanad_client/src/features/ai_chat/src/routes/ai_chat_routes.dart';
import 'package:sanad_client/src/features/home/home_page.dart';
import 'package:sanad_client/src/features/oauth/oauth_email_page.dart';
import 'package:sanad_client/src/features/oauth/oauth_otp_page.dart';
import 'package:sanad_client/src/features/oauth/oauth_otp_route_args.dart';
import 'package:sanad_client/src/features/oauth/oauth_phone_page.dart';
import 'package:sanad_client/src/features/oauth/oauth_routes.dart';
import 'package:sanad_client/src/features/oauth/oauth_screen.dart';
import 'package:sanad_client/src/features/oauth/oauth_splash_page.dart';
import 'package:sanad_client/src/features/oauth/oauth_uae_pass_collecting_page.dart';
import 'package:sanad_client/src/features/oauth/oauth_uae_pass_page.dart';
import 'package:sanad_client/src/features/oauth/oauth_uae_pass_success_page.dart';
import 'package:sanad_client/src/features/oauth/oauth_uae_pass_waiting_page.dart';
import 'package:sanad_client/src/features/oauth/uae_pass_collected_details.dart';
import 'package:sanad_client/src/features/profile/profile_page.dart';
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
  // OAuth flow (OAuthSplashPage / OAuthScreen / OAuthEmailPage) at those
  // paths instead. packages/auth stays unmodified (sanad_provider still uses
  // its screens as-is; this app still needs AuthModule for AuthBloc/session/
  // OTP). Do not remove this filter: without it GoRouter throws
  // GoError('Duplicate path') at startup.
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

      // A build on the deterministic local journey has no live session, so the
      // auth gate would only bounce every protected route to a sign-in that
      // cannot complete. Let navigation through untouched; `useMockBackend` is
      // a compile-time constant, so this is tree-shaken out of a live build.
      if (AppConfig.useMockBackend) return null;

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
            path: OAuthRoutes.splash,
            builder: (context, state) => const OAuthSplashPage(),
          ),
          GoRoute(
            path: OAuthRoutes.screen,
            builder: (context, state) => const OAuthScreen(),
          ),
          GoRoute(
            path: OAuthRoutes.email,
            builder: (context, state) => const OAuthEmailPage(),
          ),
          GoRoute(
            path: OAuthRoutes.phone,
            builder: (context, state) => const OAuthPhonePage(),
          ),
          GoRoute(
            path: OAuthRoutes.uaePass,
            builder: (context, state) => const OAuthUaePassPage(),
          ),
          GoRoute(
            path: OAuthRoutes.uaePassWaiting,
            builder: (context, state) => const OAuthUaePassWaitingPage(),
          ),
          GoRoute(
            path: OAuthRoutes.uaePassCollecting,
            builder: (context, state) => const OAuthUaePassCollectingPage(),
          ),
          GoRoute(
            path: OAuthRoutes.uaePassSuccess,
            builder: (context, state) => OAuthUaePassSuccessPage(
              details: state.extra is UaePassCollectedDetails
                  ? state.extra! as UaePassCollectedDetails
                  : null,
            ),
          ),
          GoRoute(
            path: OAuthRoutes.otp,
            // Navigating here without a valid extra bounces back to the
            // OAuth entry screen, mirroring AuthShell.otpRoute's own
            // defensive redirect for the real auth OTP route.
            redirect: (context, state) =>
                state.extra is OAuthOtpRouteArgs ? null : OAuthRoutes.screen,
            builder: (context, state) {
              // The route-level `redirect` above guards *navigation*, but not
              // a background *rebuild*: when auth status flips to
              // authenticated, `refreshListenable` makes go_router re-parse
              // the whole stack, and the imperative `extra` is not retained on
              // that pass. If this route is still in the back stack at that
              // moment, its builder re-runs with a null `extra` while its
              // redirect does not re-fire — so force-unwrapping here threw
              // "Null check operator used on a null value". Degrade to an
              // empty frame instead; the redirect moves us on the next parse.
              final args = state.extra;
              if (args is! OAuthOtpRouteArgs) return const SizedBox.shrink();
              return buildOAuthOtpRoutePage(context, args);
            },
          ),
          ...filteredModuleRoutes,
          // Inside the shell, alongside the module routes, because Profile
          // pushes one of them: Account Settings (C-11). A `ShellRoute` builds
          // its own page, so pushing an in-shell route from an out-of-shell
          // one stacks a *second* shell page with the same key and trips
          // Navigator's `!keyReservation.contains(key)` assert. Keeping the
          // two on the same side of the shell means the push reuses the shell
          // already on the stack.
          GoRoute(
            path: ClientRoutes.profile,
            builder: (context, state) => const ClientProfilePage(),
          ),
          AuthShell.otpRoute(
            // No post-signup onboarding token flow for the client app yet
            // (unrelated to the pre-auth OAuth screens above); a brand-new
            // account returns to login (sign-up lives in the provider app).
            onAuthenticated: (context) {
              context.go(ClientRoutes.home);
              // Fresh sign-in only — never on session restore. Non-blocking:
              // the user is already on Home when this appears.
              maybeOfferAppLock(context).ignore();
            },
            onOnboarding: (context, email, onboardingToken) =>
                context.go(AuthRoutes.login),
          ),
        ],
      ),
      // Post-authentication setup (Enter Name, Get Notified) — reached from
      // OAuth's OTP screen for both Email and Phone, but not itself part of
      // authentication-method selection, so it is its own shell rather than
      // nested under AuthShell (needs no AuthBloc/session infrastructure).
      ShellRoute(
        builder: (context, state, child) => BlocProvider(
          create: (_) => AccountSetupCubit(
            updateProfile: sl<UpdateClientProfileUseCase>(),
            sessionManager: sl<SessionManager>(),
          ),
          child: child,
        ),
        routes: [
          GoRoute(
            path: AccountSetupRoutes.enterName,
            builder: (context, state) => const EnterNamePage(),
          ),
          GoRoute(
            path: AccountSetupRoutes.getNotified,
            builder: (context, state) => const GetNotifiedPage(),
          ),
        ],
      ),
      GoRoute(
        path: ClientRoutes.home,
        // When this build uses the deterministic local journey, Home *is* the
        // AI chat shell: the client's real application shell (Chat / Requests /
        // My Life, with History reachable from its header). A redirect rather
        // than building `AiChatScreen` inline, because the chat lives inside
        // `AiHomeShell`'s `StatefulShellRoute` and building it bare here would
        // skip that shell's header entirely.
        //
        // A production build gets the placeholder `ClientHomePage` instead —
        // `AppConfig.enableAiChatShell` is a compile-time constant, so this
        // redirect and the shell it points to are both tree-shaken out of that
        // binary. This is independent of `MOCK_BACKEND`: a non-production build
        // lands on the shell whether the chat behind it talks to the agent or
        // to the deterministic local journey. Remove this branch once the live
        // agent contract is production-ready and the shell can front prod too.
        redirect: (context, state) =>
            AppConfig.enableAiChatShell ? AiChatRoutes.chat : null,
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
