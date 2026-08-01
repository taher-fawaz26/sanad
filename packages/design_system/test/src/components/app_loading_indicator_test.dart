import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

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
  group('AppLoadingIndicator.generateFramePaths', () {
    test('generates zero-padded sprite paths from index 0', () {
      expect(
        AppLoadingIndicator.generateFramePaths(frameCount: 7),
        [
          'assets/lottie/sprite_000.png',
          'assets/lottie/sprite_001.png',
          'assets/lottie/sprite_002.png',
          'assets/lottie/sprite_003.png',
          'assets/lottie/sprite_004.png',
          'assets/lottie/sprite_005.png',
          'assets/lottie/sprite_006.png',
        ],
      );
    });

    test('supports custom folder and prefix', () {
      expect(
        AppLoadingIndicator.generateFramePaths(
          frameCount: 2,
          assetFolder: 'assets/loading',
          assetPrefix: 'frame_',
        ),
        [
          'assets/loading/frame_000.png',
          'assets/loading/frame_001.png',
        ],
      );
    });
  });

  group('AppLoadingIndicator', () {
    testWidgets('renders without throwing', (tester) async {
      await _pump(tester, const AppLoadingIndicator());

      expect(find.byType(AppLoadingIndicator), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('respects custom size', (tester) async {
      await _pump(tester, const AppLoadingIndicator(size: 64));

      final sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(AppLoadingIndicator),
          matching: find.byType(SizedBox),
        ),
      );
      expect(sizedBox.width, 64.0);
      expect(sizedBox.height, 64.0);
    });

    testWidgets('uses AnimatedBuilder for frame updates', (tester) async {
      await _pump(tester, const AppLoadingIndicator());

      expect(
        find.descendant(
          of: find.byType(AppLoadingIndicator),
          matching: find.byType(AnimatedBuilder),
        ),
        findsOneWidget,
      );
    });

    testWidgets('loads first generated sprite path by default', (tester) async {
      await _pump(tester, const AppLoadingIndicator());

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.image, isA<AssetImage>());
      expect(
        (image.image as AssetImage).assetName,
        'assets/lottie/sprite_0000.png',
      );
    });

    testWidgets('advances displayed frame over time', (tester) async {
      await _pump(
        tester,
        const AppLoadingIndicator(duration: Duration(milliseconds: 500)),
      );

      final imageBefore = tester.widget<Image>(find.byType(Image));
      final assetBefore = (imageBefore.image as AssetImage).assetName;

      await tester.pump(const Duration(milliseconds: 200));

      final imageAfter = tester.widget<Image>(find.byType(Image));
      final assetAfter = (imageAfter.image as AssetImage).assetName;

      expect(assetAfter, isNot(equals(assetBefore)));
    });

    testWidgets('contains a RepaintBoundary', (tester) async {
      await _pump(tester, const AppLoadingIndicator());

      expect(
        find.descendant(
          of: find.byType(AppLoadingIndicator),
          matching: find.byType(RepaintBoundary),
        ),
        findsOneWidget,
      );
    });
  });
}
