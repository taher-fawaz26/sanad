// Regression: the Account Settings → "Enter Phone Number" bottom sheet must
// consume an Android system-back / edge-swipe. Before the fix, the back intent
// popped the underlying Account Settings route (navigating to the shell home)
// while the root-level sheet stayed mounted — floating over an unrelated page.
//
// Structure mirrors the provider app: an outer ShellRoute (implicit nested
// navigator, like AuthShell) with a StatefulShellRoute (Home tab) plus the
// full-screen /settings/account sibling. The phone sheet is pushed on the ROOT
// navigator via SheetNavigator, while Account Settings lives on the nested
// navigator.
//
// EasyLocalization is not bootstrapped, so `.tr()` returns the raw key — the
// sheet title assertion matches the raw i18n key (same convention as
// add_or_change_owner_phone_sheet_test.dart).
import 'dart:async';

import 'package:account_settings/src/presentation/widgets/bottom_sheets/add_or_change_owner_phone_sheet.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _sheetTitleKey = 'settings.enter_phone_title';

GoRouter _buildRouter() {
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
                    builder: (_, _) => const Scaffold(
                      body: Center(child: Text('PROVIDER_HOME')),
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/settings/account',
            builder: (context, state) => Scaffold(
              appBar: AppBar(title: const Text('ACCOUNT_SETTINGS')),
              body: Center(
                child: ElevatedButton(
                  onPressed: () =>
                      showAddOrChangeOwnerPhoneSheet(context: context),
                  child: const Text('CHANGE PHONE'),
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

Future<void> _openAccountAndPhoneSheet(
  WidgetTester tester,
  GoRouter router,
) async {
  unawaited(router.push('/settings/account'));
  await tester.pumpAndSettle();
  expect(find.text('CHANGE PHONE'), findsOneWidget);
  await tester.tap(find.text('CHANGE PHONE'));
  await tester.pumpAndSettle();
  expect(find.text(_sheetTitleKey), findsOneWidget);
}

void main() {
  group('Account Settings → phone sheet, system back', () {
    testWidgets(
      'system back does not navigate Account Settings away and does not leave '
      'the sheet floating over Provider Home',
      (tester) async {
        final router = _buildRouter();
        await _pump(tester, router);
        await _openAccountAndPhoneSheet(tester, router);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        // Underlying route is still Account Settings — NOT Provider Home.
        expect(find.text('ACCOUNT_SETTINGS'), findsOneWidget);
        expect(find.text('CHANGE PHONE'), findsOneWidget);
        expect(find.text('PROVIDER_HOME'), findsNothing);

        // The sheet is not left floating over a changed route: back dismissed
        // the (dismissible) sheet cleanly.
        expect(find.text(_sheetTitleKey), findsNothing);
      },
    );

    testWidgets(
      'after the sheet closes, a system back resumes normal navigation and '
      'pops Account Settings back toward Home',
      (tester) async {
        final router = _buildRouter();
        await _pump(tester, router);
        await _openAccountAndPhoneSheet(tester, router);

        // Close the sheet via back.
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text(_sheetTitleKey), findsNothing);
        expect(find.text('ACCOUNT_SETTINGS'), findsOneWidget);

        // Sheet gone → the next back pops Account Settings itself.
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('ACCOUNT_SETTINGS'), findsNothing);
        expect(find.text('PROVIDER_HOME'), findsOneWidget);
      },
    );
  });
}
