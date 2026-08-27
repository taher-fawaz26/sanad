import 'package:app_animations/app_animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget Function(BuildContext) build, {
  bool reduceMotion = false,
}) async {
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: MaterialApp(home: Builder(builder: build)),
    ),
  );
}

void main() {
  group('AppEffects', () {
    testWidgets('appFadeIn renders the child', (tester) async {
      await _pump(
        tester,
        (context) => const Text('hello').appFadeIn(context),
      );
      await tester.pumpAndSettle();
      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('appFadeSlideUp wraps with Animate normally', (tester) async {
      await _pump(
        tester,
        (context) => const Text('hello').appFadeSlideUp(context),
      );
      expect(find.byType(Animate), findsOneWidget);
      expect(find.text('hello'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets(
      'appFadeSlideUp collapses to opacity-only under reduced motion',
      (tester) async {
        await _pump(
          tester,
          (context) => const Text('hello').appFadeSlideUp(context),
          reduceMotion: true,
        );
        // Still wrapped by Animate (appFadeIn), but no translate effect.
        expect(find.byType(Animate), findsOneWidget);
        expect(find.text('hello'), findsOneWidget);
        await tester.pumpAndSettle();
      },
    );

    testWidgets('appScaleIn no-ops entirely under reduced motion', (
      tester,
    ) async {
      await _pump(
        tester,
        (context) => const Text('hello').appScaleIn(context),
        reduceMotion: true,
      );
      expect(find.byType(Animate), findsNothing);
      expect(find.text('hello'), findsOneWidget);
    });
  });
}
