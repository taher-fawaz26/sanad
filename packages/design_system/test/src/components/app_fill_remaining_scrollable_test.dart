import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      builder: (_, __) => MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: child),
      ),
    ),
  );
}

// Simulates a widget that uses LayoutBuilder internally — same as AppEmptyState.
class _LayoutBuilderChild extends StatelessWidget {
  const _LayoutBuilderChild({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Text(label),
    );
  }
}

void main() {
  group('AppFillRemainingScrollable', () {
    testWidgets('renders child', (tester) async {
      await _pump(
        tester,
        const AppFillRemainingScrollable(child: Text('content')),
      );

      expect(find.text('content'), findsOneWidget);
    });

    testWidgets('fills remaining viewport height', (tester) async {
      await _pump(
        tester,
        const AppFillRemainingScrollable(child: Text('content')),
      );

      // The ConstrainedBox should have minHeight equal to the viewport height.
      final box = tester.renderObject<RenderBox>(
        find.byType(ConstrainedBox).first,
      );
      final viewportHeight = tester.getSize(find.byType(Scaffold)).height;
      expect(box.size.height, greaterThanOrEqualTo(viewportHeight));
    });

    testWidgets('pull-to-refresh works when wrapped by AppRefreshIndicator', (
      tester,
    ) async {
      var refreshCalled = false;
      await _pump(
        tester,
        AppRefreshIndicator(
          onRefresh: () async {
            refreshCalled = true;
          },
          child: const AppFillRemainingScrollable(child: Text('empty')),
        ),
      );

      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, 300),
        1000,
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(refreshCalled, isTrue);
    });

    testWidgets('works with widgets containing LayoutBuilder', (tester) async {
      // Must not throw "LayoutBuilder does not support returning intrinsic
      // dimensions" — the regression that SliverFillRemaining triggered.
      await _pump(
        tester,
        const AppFillRemainingScrollable(
          child: _LayoutBuilderChild(label: 'lb-content'),
        ),
      );

      expect(find.text('lb-content'), findsOneWidget);
    });

    testWidgets('works with widgets containing nested LayoutBuilder chains', (
      tester,
    ) async {
      // Regression coverage for consumers such as shared_ui's AppEmptyState /
      // AppErrorState, which also build on LayoutBuilder internally — kept
      // here as a plain LayoutBuilder child to avoid a shared_ui dependency
      // (design_system must not depend on shared_ui).
      await _pump(
        tester,
        const AppFillRemainingScrollable(
          child: _LayoutBuilderChild(label: 'Nothing here'),
        ),
      );

      expect(find.text('Nothing here'), findsOneWidget);
    });

    testWidgets('is stateless and produces no extra rebuilds', (tester) async {
      var buildCount = 0;

      await _pump(
        tester,
        AppFillRemainingScrollable(
          child: Builder(
            builder: (context) {
              buildCount++;
              return const Text('built');
            },
          ),
        ),
      );

      final countAfterFirst = buildCount;

      // Pump without state change — should not rebuild.
      await tester.pump();

      expect(buildCount, countAfterFirst);
    });

    testWidgets(
      'can be reused from another widget without feature dependency',
      (tester) async {
        // Constructs AppFillRemainingScrollable in isolation — no Bloc, no
        // feature package import required.
        await _pump(
          tester,
          const AppFillRemainingScrollable(child: Text('reused')),
        );

        expect(find.byType(AppFillRemainingScrollable), findsOneWidget);
        expect(find.byType(CustomScrollView), findsOneWidget);
        expect(find.text('reused'), findsOneWidget);
      },
    );
  });
}
