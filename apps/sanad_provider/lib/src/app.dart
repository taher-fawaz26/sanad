import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
import 'package:network/network.dart';
import 'package:sanad_provider/src/routing/app_routes.dart';
import 'package:sanad_provider/src/routing/provider_router.dart';

/// The root widget of the sanad_provider application.
class SanadProviderApp extends StatefulWidget {
  /// Creates a [SanadProviderApp].
  const SanadProviderApp({super.key});

  @override
  State<SanadProviderApp> createState() => _SanadProviderAppState();
}

class _SanadProviderAppState extends State<SanadProviderApp> {
  late final GoRouter _router;
  late final ConnectivityController _connectivity;

  @override
  void initState() {
    super.initState();
    _router = buildProviderRouter();
    _connectivity = sl<ConnectivityController>();
  }

  @override
  void dispose() {
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
                        return MaterialApp.router(
                          debugShowCheckedModeBanner: false,
                          localizationsDelegates: context.localizationDelegates,
                          supportedLocales: context.supportedLocales,
                          locale: locale,
                          theme: AppTheme.light(),
                          darkTheme: AppTheme.dark(),
                          themeMode: _resolveThemeMode(themeState),
                          routerConfig: _router,
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
    );
  }

  ThemeMode _resolveThemeMode(ThemeState state) => switch (state.mode) {
    AppThemeMode.dark => ThemeMode.dark,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.system => ThemeMode.system,
  };
}
