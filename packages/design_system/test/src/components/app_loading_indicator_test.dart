import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

// ─── Helpers ─────────────────────────────────────────────────────────────────

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      builder: (_, __) => MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('AppLoadingIndicator', () {
    testWidgets('renders a looping Lottie animation without throwing', (
      tester,
    ) async {
      await _pump(tester, const AppLoadingIndicator());

      expect(find.byType(AppLoadingIndicator), findsOneWidget);
      expect(find.byType(LottieBuilder), findsOneWidget);
    });

    testWidgets('respects custom size', (tester) async {
      await _pump(tester, const AppLoadingIndicator(size: 64));

      final lottie = tester.widget<LottieBuilder>(
        find.byType(LottieBuilder),
      );
      expect(lottie.width, 64.0);
      expect(lottie.height, 64.0);
    });
  });
}
