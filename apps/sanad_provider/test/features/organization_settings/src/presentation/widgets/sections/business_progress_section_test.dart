import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/widgets/sections/business_progress_section.dart';

const _surfaceSize = Size(390, 900);

const _items = [
  BusinessProgressChecklistItem(label: 'Category', completed: true),
  BusinessProgressChecklistItem(label: 'Phone number', completed: true),
  BusinessProgressChecklistItem(label: 'Services', completed: false),
];

Future<void> _pump(
  WidgetTester tester, {
  bool visibleToCustomers = false,
  bool disableAnimations = false,
}) {
  return tester.pumpWidget(
    ScreenUtilInit(
      designSize: _surfaceSize,
      minTextAdapt: true,
      builder: (_, _) => MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(disableAnimations: disableAnimations),
            child: Scaffold(
              body: SingleChildScrollView(
                child: BusinessProgressSection(
                  completionPercent: 86,
                  items: _items,
                  visibleToCustomers: visibleToCustomers,
                  requiredCompleted: 6,
                  requiredTotal: 7,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// The `turns` of the chevron's [AnimatedRotation] — `0.0` pointing down
/// (collapsed), `0.5` flipped up (expanded).
double _chevronTurns(WidgetTester tester) {
  final rotation = tester.widget<AnimatedRotation>(
    find.ancestor(
      of: find.byIcon(Icons.keyboard_arrow_down),
      matching: find.byType(AnimatedRotation),
    ),
  );
  return rotation.turns;
}

void main() {
  group('BusinessProgressSection', () {
    testWidgets('is collapsed by default: summary shown, checklist hidden', (
      tester,
    ) async {
      await _pump(tester);

      // Collapsed summary is visible: title + required footer.
      expect(find.text('settings.business_progress_title'), findsOneWidget);
      expect(
        find.textContaining('settings.business_progress_required_completed'),
        findsOneWidget,
      );
      expect(find.text('6 / 7'), findsOneWidget);

      // Expandable body is hidden.
      expect(find.text('Category'), findsNothing);
      expect(find.text('Services'), findsNothing);
      expect(
        find.text('settings.business_progress_hidden_badge'),
        findsNothing,
      );

      // Chevron points down when collapsed.
      expect(_chevronTurns(tester), 0.0);
    });

    testWidgets('tapping expands the checklist and flips the chevron', (
      tester,
    ) async {
      await _pump(tester);

      await tester.tap(find.text('settings.business_progress_title'));
      await tester.pumpAndSettle();

      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Services'), findsOneWidget);
      // Not yet visible to customers → hidden-from-customers badge appears.
      expect(
        find.text('settings.business_progress_hidden_badge'),
        findsOneWidget,
      );
      expect(_chevronTurns(tester), 0.5);
    });

    testWidgets('tapping again collapses it back', (tester) async {
      await _pump(tester);

      await tester.tap(find.text('settings.business_progress_title'));
      await tester.pumpAndSettle();
      expect(find.text('Category'), findsOneWidget);

      await tester.tap(find.text('settings.business_progress_title'));
      await tester.pumpAndSettle();

      expect(find.text('Category'), findsNothing);
      expect(_chevronTurns(tester), 0.0);
    });

    testWidgets(
      'reduced motion: expands instantly on a single pump (zero-duration)',
      (tester) async {
        await _pump(tester, disableAnimations: true);

        await tester.tap(find.text('settings.business_progress_title'));
        // No settle — with reduced motion the body is laid out on the next
        // frame with no implicit animation to wait out.
        await tester.pump();

        expect(find.text('Category'), findsOneWidget);
        // Reduced motion swaps AnimatedRotation for a static Transform.rotate,
        // so the chevron reflects the expanded state without an animation.
        expect(find.byType(AnimatedRotation), findsNothing);
        expect(find.byType(Transform), findsWidgets);
      },
    );

    testWidgets(
      'a fully-visible profile hides the hidden-from-customers badge even when '
      'expanded',
      (tester) async {
        await _pump(tester, visibleToCustomers: true);

        await tester.tap(find.text('settings.business_progress_title'));
        await tester.pumpAndSettle();

        expect(find.text('Category'), findsOneWidget);
        expect(
          find.text('settings.business_progress_hidden_badge'),
          findsNothing,
        );
      },
    );
  });
}
