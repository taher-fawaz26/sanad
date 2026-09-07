import 'package:app_animations/app_animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppStaggeredColumn', () {
    testWidgets('renders every child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppStaggeredColumn(
              children: [Text('a'), Text('b'), Text('c')],
            ),
          ),
        ),
      );

      expect(find.text('a'), findsOneWidget);
      expect(find.text('b'), findsOneWidget);
      expect(find.text('c'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('animates its children on first mount', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppStaggeredColumn(children: [Text('a'), Text('b')]),
          ),
        ),
      );

      // One Animate per child on the first build.
      expect(find.byType(Animate), findsNWidgets(2));
      await tester.pumpAndSettle();
    });

    testWidgets('plays once — does not replay on an unrelated rebuild', (
      tester,
    ) async {
      final notifier = ValueNotifier(0);
      addTearDown(notifier.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<int>(
              valueListenable: notifier,
              builder: (context, value, _) => AppStaggeredColumn(
                children: [Text('value $value')],
              ),
            ),
          ),
        ),
      );
      expect(find.byType(Animate), findsOneWidget);
      await tester.pumpAndSettle();

      // A rebuild that keeps the same AppStaggeredColumn element must not
      // re-wrap the children in a fresh entrance.
      notifier.value = 1;
      await tester.pump();

      expect(find.text('value 1'), findsOneWidget);
      expect(
        find.byType(Animate),
        findsNothing,
        reason: 'entrance must not replay on a later rebuild',
      );
    });

    testWidgets('leaves no pending timer (bounded pump friendly)', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppStaggeredColumn(
              children: [Text('a'), Text('b'), Text('c')],
            ),
          ),
        ),
      );

      // A few bounded pumps rather than pumpAndSettle — mirrors the OTP
      // screen's discipline. No "Timer is still pending" must surface.
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('c'), findsOneWidget);
    });

    testWidgets('renders children with no motion under reduced motion', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(
              body: AppStaggeredColumn(children: [Text('a'), Text('b')]),
            ),
          ),
        ),
      );

      expect(find.byType(Animate), findsNothing);
      expect(find.text('a'), findsOneWidget);
      expect(find.text('b'), findsOneWidget);
    });
  });
}
