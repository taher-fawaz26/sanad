import 'package:account_settings/account_settings.dart';
import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:deep_linking/deep_linking.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
import 'package:network/network.dart';
import 'package:otp/otp.dart';
import 'package:sanad_provider/src/lifecycle/permission_resync.dart';
import 'package:sanad_provider/src/lock/app_lock_binding.dart';
import 'package:sanad_provider/src/routing/app_routes.dart';
import 'package:sanad_provider/src/routing/provider_router.dart';

/// The root widget of the sanad_provider application.
class SanadProviderApp extends StatefulWidget {
  /// Creates a [SanadProviderApp].
  const SanadProviderApp({super.key});

  @override
  State<SanadProviderApp> createState() => _SanadProviderAppState();
}

class _SanadProviderAppState extends State<SanadProviderApp>
    with WidgetsBindingObserver {
  late final GoRouter _router;
  late final ConnectivityController _connectivity;
  late final DeepLinkDispatcher _deepLinkDispatcher;
  late final PermissionResync _permissionResync;
  late final AppLockController _appLock;
  late final AppLockBinding _appLockBinding;

  @override
  void initState() {
    super.initState();
    _router = buildProviderRouter();
    _connectivity = sl<ConnectivityController>();
    _deepLinkDispatcher = DeepLinkDispatcher(
      service: sl<DeepLinkingService>(),
      onNavigate: _router.go,
    );
    _deepLinkDispatcher.start().ignore();
    _permissionResync = PermissionResync(
      sessionManager: sl<SessionManager>(),
      getCurrentUserUseCase: sl<GetCurrentUserUseCase>(),
    );
    _appLock = sl<AppLockController>();
    _appLockBinding = AppLockBinding(_appLock);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The lock gate sees every transition and decides for itself which ones
    // matter (see AppLockBinding); it must run first so the barrier is armed
    // before anything else reacts to the app coming back.
    _appLockBinding.onLifecycleStateChanged(state);

    if (state == AppLifecycleState.resumed) {
      // Fire-and-forget: a silent background resync, not a user-facing flow.
      // See PermissionResync's doc comment for why this exists.
      _permissionResync().ignore();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _deepLinkDispatcher.stop().ignore();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConnectivityOfflineGate(
      controller: _connectivity,
      router: _router,
      // Pass the app's own route constant rather than leaning on the gate's
      // default string, so the two never drift apart.
      // ignore: avoid_redundant_argument_values
      offlinePath: AppRoutes.offline,
      child: GestureDetector(
        onTap: () => primaryFocus?.unfocus(),
        child: MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => sl<ThemeBloc>()),
            BlocProvider(create: (_) => sl<TranslateBloc>()),
          ],
          // The single place the app applies a locale to EasyLocalization.
          // Mounted inside the TranslateBloc provider (so it can subscribe)
          // and inside EasyLocalization (so it can call setLocale), above the
          // router — so a language change rebuilds in place rather than
          // recreating pages.
          child: AppLocaleSync(
            child: BlocBuilder<ThemeBloc, ThemeState>(
              builder: (context, themeState) {
                return Builder(
                  builder: (context) {
                    final locale = context.locale;
                    final mediaQuery = MediaQuery.of(context);
                    final systemScale = mediaQuery.textScaler.scale(1);
                    final safeScale = systemScale.clamp(0.9, 1.3);
                    return MediaQuery(
                      data: mediaQuery.copyWith(
                        textScaler: TextScaler.linear(safeScale),
                      ),
                      child: ScreenUtilInit(
                        designSize: const Size(360, 800),
                        useInheritedMediaQuery: true,
                        minTextAdapt: true,
                        splitScreenMode: true,
                        builder: (_, _) {
                          return AppLockGate(
                            controller: _appLock,
                            themeMode: _resolveThemeMode(themeState),
                            localizationsDelegates:
                                context.localizationDelegates,
                            supportedLocales: context.supportedLocales,
                            locale: locale,
                            // The provider app's OTP screens follow the
                            // provider Figma spec. Declared once here so the
                            // OTP call sites inside shared packages (`auth`
                            // sign-in, `account_settings` deletion,
                            // `contact_verification`) render this app's
                            // design without taking a style parameter.
                            child: OtpStyleScope(
                              style: OtpVisualStyle.provider,
                              child: MaterialApp.router(
                                debugShowCheckedModeBanner: false,
                                localizationsDelegates:
                                    context.localizationDelegates,
                                supportedLocales: context.supportedLocales,
                                locale: locale,
                                theme: AppTheme.light(),
                                darkTheme: AppTheme.dark(),
                                themeMode: _resolveThemeMode(themeState),
                                routerConfig: _router,
                                // SAN-581. Android (with
                                // `enableOnBackInvokedCallback=true`, set in
                                // our manifest) decides whether to even ASK
                                // Flutter about a back gesture from a latched
                                // boolean, pushed here via
                                // `setFrameworkHandlesBack`.
                                //
                                // `NavigationNotification`s bubble UP the
                                // widget tree, and the listener that corrects a
                                // `false` into a `true` lives INSIDE
                                // `NavigatorState.build` — a DESCENDANT of that
                                // navigator's own element
                                // (flutter/widgets/navigator.dart). But
                                // `_handleHistoryChanged` dispatches at the
                                // navigator's OWN context, so a navigator's
                                // history change bypasses its own corrector and
                                // every nested navigator below it.
                                //
                                // Our root navigator holds exactly one page
                                // (the StatefulShellRoute shell), so its
                                // `canPop()` is false and it emits
                                // `canHandlePop:false`. `SheetNavigator` pushes
                                // sheets onto THAT root navigator, so closing
                                // one emits that `false` last — latching
                                // "Flutter can't handle back" even though the
                                // shell branch has a deep, poppable stack (e.g.
                                // List > Details > Edit). Android then exits
                                // the app without ever calling into Flutter,
                                // which is why no PopScope or go_router change
                                // can rescue it.
                                //
                                // go_router's own `canPop()` walks the shell
                                // branches the framework's notification skips,
                                // so OR-ing it in restores the truth. The OR
                                // also preserves PopScope interception, which
                                // reports `canHandlePop:true` precisely when it
                                // wants to block a pop.
                                onNavigationNotification: (notification) {
                                  SystemNavigator.setFrameworkHandlesBack(
                                    notification.canHandlePop ||
                                        _router.canPop(),
                                  );
                                  return true;
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  ThemeMode _resolveThemeMode(ThemeState state) => switch (state.mode) {
    AppThemeMode.dark => ThemeMode.dark,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.system => ThemeMode.system,
  };
}
