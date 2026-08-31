import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// No EasyLocalization bootstrap — `.tr()` falls back to the raw key (see
/// `packages/auth/test/src/presentation/pages/auth_page_test.dart` for the
/// same convention). `EasyLocalization.ensureInitialized()` hangs
/// indefinitely in this repo's widget-test sandbox (a test-harness/plugin
/// limitation, unrelated to this feature), so OAuth widgets read the
/// current locale from Flutter's own `Localizations.localeOf` rather than
/// easy_localization's `context.locale` — the former works fine here with
/// no bootstrap.
///
/// Uses a realistic phone-sized test surface (matches the convention in
/// `add_service_navigation_test.dart`) — the default 800×600 test window is
/// wider than tall, unlike any real phone, and these screens are content
/// heavy enough that the default surface isn't representative.
Future<void> pumpOAuth(WidgetTester tester, Widget home) async {
  await tester.binding.setSurfaceSize(const Size(1080, 2400));
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      builder: (_, _) => MaterialApp(theme: AppTheme.light(), home: home),
    ),
  );
  // Settles AppPageEntrance's one-shot fade/slide-in animation so no timer
  // is left pending when the test ends.
  await tester.pumpAndSettle();
}

/// As [pumpOAuth], but hosts [router] instead of a single `home` widget —
/// for tests that assert navigation between OAuth screens.
Future<void> pumpOAuthRouter(WidgetTester tester, GoRouter router) async {
  await tester.binding.setSurfaceSize(const Size(1080, 2400));
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      builder: (_, _) => MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: router,
      ),
    ),
  );
  // Settles AppPageEntrance's one-shot fade/slide-in animation so no timer
  // is left pending when the test ends. Does not wait out
  // OAuthSplashPage's longer navigation delay — tests that need that call an
  // additional pumpAndSettle(duration) themselves.
  await tester.pumpAndSettle();
}
