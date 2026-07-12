import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// Default design size matching the Sanad mobile layout baseline.
const testDesignSize = Size(360, 800);

/// Returns a [MaterialApp] configured for widget tests.
Widget buildTestApp({
  required Widget home,
  ThemeData? theme,
  ThemeData? darkTheme,
  ThemeMode themeMode = ThemeMode.light,
}) {
  return MaterialApp(
    theme: theme ?? AppTheme.light(),
    darkTheme: darkTheme ?? AppTheme.dark(),
    themeMode: themeMode,
    home: home,
  );
}

/// Pumps [child] wrapped in [ScreenUtilInit] + light [AppTheme].
Future<void> pumpDsWidget(
  WidgetTester tester,
  Widget child, {
  Size designSize = testDesignSize,
}) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: designSize,
      minTextAdapt: true,
      builder: (_, __) => buildTestApp(home: child),
    ),
  );
}

/// Pumps [child] wrapped in [ScreenUtilInit] + dark [AppTheme].
Future<void> pumpDsWidgetDark(
  WidgetTester tester,
  Widget child, {
  Size designSize = testDesignSize,
}) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: designSize,
      minTextAdapt: true,
      builder: (_, __) => buildTestApp(
        home: child,
        themeMode: ThemeMode.dark,
      ),
    ),
  );
}
