import 'package:app_animations/app_animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpGradient(
    WidgetTester tester, {
    bool reduceMotion = false,
    Widget? child,
  }) => tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: MaterialApp(
        home: Scaffold(
          body: AppAmbientGradient(color: Colors.green, child: child),
        ),
      ),
    ),
  );

  testWidgets('renders its child, unaffected by the animated backdrop', (
    tester,
  ) async {
    await pumpGradient(tester, child: const Text('conversation'));

    expect(find.text('conversation'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('conversation'), findsOneWidget);
  });

  testWidgets('renders with no child at all', (tester) async {
    await pumpGradient(tester);

    expect(find.byType(AppAmbientGradient), findsOneWidget);
  });

  testWidgets('animates continuously under normal motion', (tester) async {
    await pumpGradient(tester);

    final painterAt = <CustomPainter?>[];
    void capture() => painterAt.add(
      tester.widget<CustomPaint>(find.byKey(ambientGlowPainterKey)).painter,
    );

    capture();
    await tester.pump(const Duration(seconds: 4));
    capture();
    await tester.pump(const Duration(seconds: 4));
    capture();

    // Each tick is a genuinely new painter instance carrying a new `t` — the
    // glow is actually moving, not merely mounted.
    expect(painterAt[0], isNot(equals(painterAt[1])));
    expect(painterAt[1], isNot(equals(painterAt[2])));

    // Tears down its own ticker cleanly.
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('does not animate under reduced motion', (tester) async {
    await pumpGradient(tester, reduceMotion: true);

    final painter = tester
        .widget<CustomPaint>(find.byKey(ambientGlowPainterKey))
        .painter;

    await tester.pump(const Duration(seconds: 4));

    // A still glow is still a glow: the backdrop is present, just not
    // drifting — the same painter instance, unchanged, is exactly that.
    expect(
      tester.widget<CustomPaint>(find.byKey(ambientGlowPainterKey)).painter,
      equals(painter),
    );
  });

  testWidgets('an empty size does not throw', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox.shrink(child: AppAmbientGradient(color: Colors.green)),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
