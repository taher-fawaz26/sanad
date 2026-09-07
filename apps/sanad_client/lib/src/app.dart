import 'package:account_settings/account_settings.dart';
import 'package:core/core.dart';
import 'package:deep_linking/deep_linking.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
import 'package:network/network.dart';
import 'package:otp/otp.dart';
import 'package:sanad_client/src/lock/app_lock_binding.dart';
import 'package:sanad_client/src/routing/client_router.dart';

/// The root widget of the sanad_client application.
class SanadClientApp extends StatefulWidget {
  /// Creates a [SanadClientApp].
  const SanadClientApp({super.key});

  @override
  State<SanadClientApp> createState() => _SanadClientAppState();
}

class _SanadClientAppState extends State<SanadClientApp>
    with WidgetsBindingObserver {
  late final GoRouter _router;
  late final ConnectivityController _connectivity;
  late final DeepLinkDispatcher _deepLinkDispatcher;
  late final AppLockController _appLock;
  late final AppLockBinding _appLockBinding;

  @override
  void initState() {
    super.initState();
    _router = buildClientRouter();
    _connectivity = sl<ConnectivityController>();
    _deepLinkDispatcher = DeepLinkDispatcher(
      service: sl<DeepLinkingService>(),
      onNavigate: _router.go,
    );
    _deepLinkDispatcher.start().ignore();
    _appLock = sl<AppLockController>();
    _appLockBinding = AppLockBinding(_appLock);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appLockBinding.onLifecycleStateChanged(state);
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
                            // The client app's OTP screens follow the client
                            // Figma spec. Declared once here so the OTP call
                            // sites inside shared packages (`auth` sign-in,
                            // `account_settings` deletion) render this app's
                            // design without taking a style parameter.
                            child: OtpStyleScope(
                              style: OtpVisualStyle.client,
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
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
    AppThemeMode.system => ThemeMode.system,
  };
}
