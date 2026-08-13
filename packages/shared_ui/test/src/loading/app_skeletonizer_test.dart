import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  TextDirection direction = TextDirection.ltr,
}) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      builder: (_, _) => MaterialApp(
        theme: AppTheme.light(),
        home: Directionality(
          textDirection: direction,
          child: Scaffold(body: child),
        ),
      ),
    ),
  );
}

void main() {
  group('AppSkeletonizer', () {
    testWidgets('disabled renders the real content', (tester) async {
      await _pump(
        tester,
        const AppSkeletonizer(enabled: false, child: Text('content')),
      );

      expect(find.text('content'), findsOneWidget);
      final widget = tester.widget<AppSkeletonizer>(
        find.byType(AppSkeletonizer),
      );
      expect(widget.enabled, isFalse);
    });

    testWidgets('enabled preserves the child widget subtree', (tester) async {
      await _pump(
        tester,
        const AppSkeletonizer(enabled: true, child: Text('content')),
      );

      // Skeletonizer paints bones but keeps the real widget tree in place, so
      // the child must still be present (no empty-screen wipe).
      expect(find.text('content'), findsOneWidget);
      final widget = tester.widget<AppSkeletonizer>(
        find.byType(AppSkeletonizer),
      );
      expect(widget.enabled, isTrue);
    });

    testWidgets('renders correctly in RTL', (tester) async {
      await _pump(
        tester,
        const AppSkeletonizer(enabled: true, child: Text('محتوى')),
        direction: TextDirection.rtl,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('محتوى'), findsOneWidget);
    });

    testWidgets('sliver variant renders inside a CustomScrollView', (
      tester,
    ) async {
      await _pump(
        tester,
        CustomScrollView(
          slivers: const [
            AppSkeletonizer.sliver(
              enabled: true,
              child: SliverToBoxAdapter(child: Text('sliver-content')),
            ),
          ],
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('sliver-content'), findsOneWidget);
    });
  });

  group('AppSkeletonList', () {
    testWidgets('renders itemCount placeholder rows', (tester) async {
      await _pump(
        tester,
        AppSkeletonList(
          itemCount: 4,
          itemBuilder: (context, index) => Text('row $index'),
        ),
      );

      expect(find.textContaining('row '), findsNWidgets(4));
    });

    testWidgets('does not overflow when placeholders exceed the viewport', (
      tester,
    ) async {
      await _pump(
        tester,
        SizedBox(
          height: 200,
          child: AppSkeletonList(
            itemCount: 6,
            itemBuilder: (_, _) => const SizedBox(height: 180),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
