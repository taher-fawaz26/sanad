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

Widget _buildList({int itemCount = 10}) {
  return ListView.builder(
    physics: const AlwaysScrollableScrollPhysics(),
    itemCount: itemCount,
    itemBuilder: (_, i) => ListTile(title: Text('Item $i')),
  );
}

Widget _buildEmptyScrollable() {
  return const AppFillRemainingScrollable(child: Text('Empty'));
}

void main() {
  group('AppRefreshIndicator', () {
    testWidgets('invokes onRefresh callback', (tester) async {
      var refreshCalled = false;
      await _pump(
        tester,
        AppRefreshIndicator(
          onRefresh: () async {
            refreshCalled = true;
          },
          child: _buildList(),
        ),
      );

      await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(refreshCalled, isTrue);
    });

    testWidgets('works with populated list', (tester) async {
      var refreshCount = 0;
      await _pump(
        tester,
        AppRefreshIndicator(
          onRefresh: () async {
            refreshCount++;
          },
          child: _buildList(itemCount: 20),
        ),
      );

      expect(find.text('Item 0'), findsOneWidget);

      await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(refreshCount, 1);
    });

    testWidgets('works with empty scrollable child', (tester) async {
      var refreshCalled = false;
      await _pump(
        tester,
        AppRefreshIndicator(
          onRefresh: () async {
            refreshCalled = true;
          },
          child: _buildEmptyScrollable(),
        ),
      );

      expect(find.text('Empty'), findsOneWidget);

      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, 300),
        1000,
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(refreshCalled, isTrue);
    });

    testWidgets('works after error state content swap', (tester) async {
      var refreshCount = 0;
      final showError = ValueNotifier(true);

      await _pump(
        tester,
        ValueListenableBuilder<bool>(
          valueListenable: showError,
          builder: (_, isError, __) => AppRefreshIndicator(
            onRefresh: () async {
              refreshCount++;
            },
            child: isError ? _buildEmptyScrollable() : _buildList(itemCount: 5),
          ),
        ),
      );

      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, 300),
        1000,
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(refreshCount, 1);

      showError.value = false;
      await tester.pumpAndSettle();

      await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(refreshCount, 2);
    });

    testWidgets('uses theme colors', (tester) async {
      await _pump(
        tester,
        AppRefreshIndicator(
          onRefresh: () async {},
          child: _buildList(),
        ),
      );

      final indicator = tester.widget<RefreshIndicator>(
        find.byType(RefreshIndicator),
      );

      final context = tester.element(find.byType(AppRefreshIndicator));
      final colorScheme = Theme.of(context).colorScheme;

      expect(indicator.color, colorScheme.primary);
      expect(indicator.backgroundColor, colorScheme.surface);
    });

    testWidgets('has no feature-specific dependencies', (tester) async {
      await _pump(
        tester,
        AppRefreshIndicator(
          onRefresh: () async {},
          child: _buildList(),
        ),
      );

      expect(find.byType(AppRefreshIndicator), findsOneWidget);
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });
  });
}
