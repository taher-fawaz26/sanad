// Regression coverage for the sheet/system-back bug: while a bottom sheet is
// open, an Android system-back / edge-swipe (both the same pop intent in
// Flutter) must be consumed by the sheet — it must NOT pop the underlying
// page's navigator and leave the sheet floating over an unrelated route.
//
// The structure mirrors the real provider app: an outer ShellRoute (no
// navigatorKey → implicit nested navigator, like AuthShell) holding a
// StatefulShellRoute (Home/Settings tabs) plus a full-screen sibling route
// (/settings/account). The sheet is pushed on the ROOT navigator via
// SheetNavigator, while the page that opened it lives on the nested navigator.
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

GoRouter _buildRouter({
  bool dismissibleSheet = true,
  VoidCallback? onSheetClosed,
}) {
  return GoRouter(
    navigatorKey: GlobalKey<NavigatorState>(),
    initialLocation: '/home',
    routes: [
      ShellRoute(
        builder: (context, state, child) => child,
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, shell) => shell,
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/home',
                    builder: (_, _) =>
                        const Scaffold(body: Center(child: Text('HOME'))),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/settings',
                    builder: (context, _) => Scaffold(
                      body: Center(
                        child: ElevatedButton(
                          onPressed: () => context.push('/settings/account'),
                          child: const Text('GO ACCOUNT'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/settings/account',
            builder: (context, state) => Scaffold(
              appBar: AppBar(title: const Text('ACCOUNT')),
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    await SheetNavigator.push<void>(
                      context,
                      Builder(
                        builder: (sheetContext) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('SHEET'),
                            ElevatedButton(
                              onPressed: () => SheetNavigator.pop(sheetContext),
                              child: const Text('CLOSE SHEET'),
                            ),
                          ],
                        ),
                      ),
                      settings: SheetRouteSettings(
                        title: 'Sheet',
                        isDismissible: dismissibleSheet,
                      ),
                    );
                    onSheetClosed?.call();
                  },
                  child: const Text('OPEN SHEET'),
                ),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

Future<void> _pump(WidgetTester tester, GoRouter router) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      builder: (_, _) => MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

int _count(String text) => find.text(text).evaluate().length;

/// Settings tab → push /settings/account → open the sheet.
Future<void> _openAccountAndSheet(WidgetTester tester, GoRouter router) async {
  router.go('/settings');
  await tester.pumpAndSettle();
  await tester.tap(find.text('GO ACCOUNT'));
  await tester.pumpAndSettle();
  expect(find.text('OPEN SHEET'), findsOneWidget);
  await tester.tap(find.text('OPEN SHEET'));
  await tester.pumpAndSettle();
  expect(find.text('SHEET'), findsOneWidget);
}

/// Fling the sheet's drag handle downward hard enough to dismiss it.
Future<void> _flingSheetDown(WidgetTester tester) async {
  final dragHandle = find.byWidgetPredicate(
    (w) => w is GestureDetector && w.onVerticalDragEnd != null,
  );
  await tester.fling(dragHandle.first, const Offset(0, 300), 1500);
  await tester.pumpAndSettle();
}

void main() {
  group('system back with an open sheet (SheetNavigator + go_router)', () {
    testWidgets(
      'system back is consumed by the sheet: underlying stays Account, '
      'sheet is not left floating over another route',
      (tester) async {
        final router = _buildRouter();
        await _pump(tester, router);
        await _openAccountAndSheet(tester, router);

        final locationBefore =
            router.routerDelegate.currentConfiguration.uri.toString();

        // System back button / edge-swipe — identical pop intent in Flutter.
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        // Underlying route did NOT navigate away (still Account, not Home).
        expect(find.text('ACCOUNT'), findsOneWidget);
        expect(find.text('OPEN SHEET'), findsOneWidget);
        expect(_count('HOME'), 0);
        expect(
          router.routerDelegate.currentConfiguration.uri.toString(),
          locationBefore,
        );

        // The sheet was dismissed (a dismissible sheet closes on back) — it is
        // NOT left mounted over a changed underlying route.
        expect(find.text('SHEET'), findsNothing);
      },
    );

    testWidgets(
      'a non-dismissible sheet swallows system back entirely — sheet AND '
      'underlying both stay put',
      (tester) async {
        final router = _buildRouter(dismissibleSheet: false);
        await _pump(tester, router);
        await _openAccountAndSheet(tester, router);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        // Nothing popped: the sheet is still the top-most state, and the
        // underlying route is untouched.
        expect(find.text('SHEET'), findsOneWidget);
        expect(find.text('OPEN SHEET'), findsOneWidget);
        expect(_count('HOME'), 0);
      },
    );

    testWidgets('explicit sheet dismissal (SheetNavigator.pop) still works', (
      tester,
    ) async {
      final router = _buildRouter();
      await _pump(tester, router);
      await _openAccountAndSheet(tester, router);

      await tester.tap(find.text('CLOSE SHEET'));
      await tester.pumpAndSettle();

      expect(find.text('SHEET'), findsNothing);
      // Only the sheet closed; the underlying route is intact.
      expect(find.text('OPEN SHEET'), findsOneWidget);
    });

    testWidgets('drag-to-dismiss still works', (tester) async {
      final router = _buildRouter();
      await _pump(tester, router);
      await _openAccountAndSheet(tester, router);

      await _flingSheetDown(tester);

      expect(find.text('SHEET'), findsNothing);
      expect(find.text('OPEN SHEET'), findsOneWidget);
    });

    testWidgets(
      'closing the sheet restores normal page navigation: a subsequent '
      'system back pops Account back to Settings',
      (tester) async {
        final router = _buildRouter();
        await _pump(tester, router);
        await _openAccountAndSheet(tester, router);

        // Close the sheet.
        await tester.tap(find.text('CLOSE SHEET'));
        await tester.pumpAndSettle();
        expect(find.text('SHEET'), findsNothing);
        expect(find.text('OPEN SHEET'), findsOneWidget);

        // Now the sheet is gone, a system back pops the underlying page.
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        expect(find.text('OPEN SHEET'), findsNothing);
        expect(find.text('GO ACCOUNT'), findsOneWidget);
      },
    );

    testWidgets(
      'the open sheet declares itself the authoritative back handler '
      '(PopScope.canPop == false)',
      (tester) async {
        final router = _buildRouter();
        await _pump(tester, router);
        await _openAccountAndSheet(tester, router);

        // The sheet's own PopScope (canPop:false) wraps the sheet chrome, so
        // it is an ancestor of SheetScaffold — this is what makes the sheet
        // the authoritative back handler.
        final blockingPopScope = find.ancestor(
          of: find.byType(SheetScaffold),
          matching: find.byWidgetPredicate(
            (w) => w is PopScope && w.canPop == false,
          ),
        );
        expect(blockingPopScope, findsOneWidget);
      },
    );
  });
}
