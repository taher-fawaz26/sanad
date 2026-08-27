import 'package:app_animations/app_animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  bool reduceMotion = false,
}) async {
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: MaterialApp(
        home: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}

void main() {
  group('AppLottie', () {
    testWidgets('loading() selects the loading asset and repeats', (
      tester,
    ) async {
      await _pump(tester, AppLottie.loading());

      expect(find.byType(AppLottie), findsOneWidget);
      final lottie = tester.widget<LottieBuilder>(find.byType(LottieBuilder));
      expect(lottie.repeat, isTrue);
    });

    testWidgets('respects a custom size', (tester) async {
      await _pump(tester, AppLottie.loading(size: 64));

      final lottie = tester.widget<LottieBuilder>(find.byType(LottieBuilder));
      expect(lottie.width, 64.0);
      expect(lottie.height, 64.0);
    });

    testWidgets(
      'functional loaders keep animating under reduced motion',
      (tester) async {
        await _pump(tester, AppLottie.loading(), reduceMotion: true);

        final lottie = tester.widget<LottieBuilder>(
          find.byType(LottieBuilder),
        );
        expect(lottie.repeat, isTrue);
      },
    );

    testWidgets(
      'documentExtraction() keeps animating under reduced motion',
      (tester) async {
        await _pump(
          tester,
          AppLottie.documentExtraction(),
          reduceMotion: true,
        );

        final lottie = tester.widget<LottieBuilder>(
          find.byType(LottieBuilder),
        );
        expect(lottie.repeat, isTrue);
      },
    );

    testWidgets('notFound() plays normally without reduced motion', (
      tester,
    ) async {
      await _pump(tester, AppLottie.notFound(size: 160));

      final lottie = tester.widget<LottieBuilder>(find.byType(LottieBuilder));
      expect(lottie.repeat, isTrue);
    });

    testWidgets(
      'decorative illustrations freeze under reduced motion',
      (tester) async {
        await _pump(
          tester,
          AppLottie.notFound(size: 160),
          reduceMotion: true,
        );

        final lottie = tester.widget<LottieBuilder>(
          find.byType(LottieBuilder),
        );
        expect(lottie.repeat, isFalse);
      },
    );

    testWidgets('forbidden() freezes under reduced motion', (tester) async {
      await _pump(tester, AppLottie.forbidden(size: 160), reduceMotion: true);

      final lottie = tester.widget<LottieBuilder>(find.byType(LottieBuilder));
      expect(lottie.repeat, isFalse);
    });
  });
}
