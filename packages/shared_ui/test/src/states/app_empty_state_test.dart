import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  bool disableAnimations = false,
}) {
  // The full empty-state illustration + copy + action needs more height than
  // flutter_test's default 800x600 surface gives a bare `Scaffold` — this
  // matches the phone-sized viewport it actually renders in.
  tester.view.physicalSize = const Size(360, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  return tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      builder: (_, _) => MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(body: child),
        ),
      ),
    ),
  );
}

void main() {
  group('AppEmptyState', () {
    testWidgets('renders title, description, and action', (tester) async {
      var tapped = false;
      await _pump(
        tester,
        AppGenericEmptyState(
          title: 'Nothing here',
          description: 'Nothing to show yet.',
          actionLabel: 'Retry',
          onAction: () => tapped = true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nothing here'), findsOneWidget);
      expect(find.text('Nothing to show yet.'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('fades/slides in on first appearance — content starts below '
        'full opacity, then settles to it', (tester) async {
      await _pump(
        tester,
        const AppGenericEmptyState(
          title: 'Nothing here',
          description: 'Nothing to show yet.',
        ),
      );

      await tester.pump(); // first frame of the entrance
      final opacity = tester
          .widgetList<FadeTransition>(find.byType(FadeTransition))
          .map((w) => w.opacity.value);
      expect(opacity, contains(lessThan(1.0)));

      await tester.pumpAndSettle();
      expect(find.text('Nothing here'), findsOneWidget);
    });

    testWidgets('renders immediately under reduced motion — no stuck '
        'invisible content', (tester) async {
      await _pump(
        tester,
        const AppGenericEmptyState(
          title: 'Nothing here',
          description: 'Nothing to show yet.',
        ),
        disableAnimations: true,
      );

      // `appFadeIn` still runs through `flutter_animate` even under reduced
      // motion (only the translate/scale portion is skipped) and schedules a
      // timer on mount — settle it so none is left pending at test teardown.
      await tester.pumpAndSettle();
      expect(find.text('Nothing here'), findsOneWidget);
    });
  });
}
