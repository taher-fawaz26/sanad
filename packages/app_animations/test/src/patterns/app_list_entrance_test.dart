import 'package:app_animations/app_animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppListEntrance', () {
    testWidgets('animates on first appearance', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AppListEntrance(index: 0, child: Text('row')),
        ),
      );

      expect(find.byType(Animate), findsOneWidget);
      expect(find.text('row'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('does not replay on an unrelated parent rebuild', (
      tester,
    ) async {
      final notifier = ValueNotifier(0);
      addTearDown(notifier.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: ValueListenableBuilder<int>(
            valueListenable: notifier,
            builder: (context, value, _) {
              return AppListEntrance(
                index: 0,
                child: Text('row $value'),
              );
            },
          ),
        ),
      );
      expect(find.byType(Animate), findsOneWidget);

      // Trigger a rebuild of the parent that does NOT recreate the
      // AppListEntrance element (same position in the tree).
      notifier.value = 1;
      await tester.pump();

      expect(find.text('row 1'), findsOneWidget);
      expect(
        find.byType(Animate),
        findsNothing,
        reason: 'entrance must not replay on a later rebuild',
      );
      await tester.pumpAndSettle();
    });

    testWidgets('items beyond maxAnimatedIndex render with no motion', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AppListEntrance(index: 50, child: Text('row')),
        ),
      );

      expect(find.byType(Animate), findsNothing);
      expect(find.text('row'), findsOneWidget);
    });

    testWidgets('does not animate under reduced motion', (tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: AppListEntrance(index: 0, child: Text('row')),
          ),
        ),
      );

      expect(find.byType(Animate), findsNothing);
    });
  });
}
