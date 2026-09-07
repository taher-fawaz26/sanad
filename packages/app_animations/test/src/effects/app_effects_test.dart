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

    testWidgets('appShake shakes then settles, leaving no pending timer', (
      tester,
    ) async {
      await _pump(
        tester,
        (context) => const Text('code').appShake(context, trigger: 'err-1'),
      );

      // Wrapped in a translate that animates. Bounded pumps only (no
      // pumpAndSettle) — mirrors the OTP screen; must not leave a timer.
      expect(find.text('code'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('code'), findsOneWidget);
    });

    testWidgets('appShake is a no-op when the trigger is null', (tester) async {
      await _pump(
        tester,
        (context) => const Text('code').appShake(context, trigger: null),
      );
      expect(find.byType(TweenAnimationBuilder<double>), findsNothing);
      expect(find.text('code'), findsOneWidget);
    });

    testWidgets('appShake no-ops under reduced motion', (tester) async {
      await _pump(
        tester,
        (context) => const Text('code').appShake(context, trigger: 'err-1'),
        reduceMotion: true,
      );
      expect(find.byType(TweenAnimationBuilder<double>), findsNothing);
      expect(find.text('code'), findsOneWidget);
    });
  });
}
