import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('App composition order', () {
    testWidgets(
      'AppTheme must be built inside ScreenUtilInit — '
      'regression for LateInitializationError on startup',
      (tester) async {
        // Mirrors the production tree from app.dart:
        //   MediaQuery → ScreenUtilInit → MaterialApp(theme: AppTheme.light())
        //
        // Before the fix, AppTheme.light() was evaluated outside ScreenUtilInit
        // (as an argument to MaterialApp.router), triggering a
        // LateInitializationError in ScreenUtil._data → screenWidth →
        // responsiveFontSize → buildAppTypography → AppTheme._build.
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(),
            child: ScreenUtilInit(
              designSize: const Size(360, 800),
              useInheritedMediaQuery: true,
              minTextAdapt: true,
              splitScreenMode: true,
              builder: (_, _) {
                return MaterialApp(
                  theme: AppTheme.light(),
                  darkTheme: AppTheme.dark(),
                  home: const Scaffold(body: Placeholder()),
                );
              },
            ),
          ),
        );

        expect(find.byType(MaterialApp), findsOneWidget);
      },
    );
  });
}
