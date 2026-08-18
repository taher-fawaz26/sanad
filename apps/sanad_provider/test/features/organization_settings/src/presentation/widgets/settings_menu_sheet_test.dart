// ignore_for_file: prefer_const_constructors

import 'package:account_settings/account_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/widgets/settings_menu_sheet.dart';

// No EasyLocalization bootstrap — `.tr()` falls back to raw keys.

void main() {
  /// Pumps a two-route GoRouter with a single trigger widget that invokes
  /// [showSettingsMenuSheet] on tap. Returns the router so the test can
  /// read `currentUri` after the tap.
  ///
  /// [isProviderOwner] is passed straight through — the widget itself no
  /// longer resolves it via `sl<SessionManager>()` (RBAC action-
  /// authorization sweep: leaf presentation helpers stay free of direct
  /// DI/session reads; `MainShell`, the real composition root, resolves
  /// this once and threads it in).
  Future<GoRouter> pumpTrigger(
    WidgetTester tester, {
    required bool isProviderOwner,
  }) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Builder(
              builder: (innerContext) => TextButton(
                onPressed: () => showSettingsMenuSheet(
                  innerContext,
                  isProviderOwner: isProviderOwner,
                ),
                child: const Text('open-settings'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: AccountSettingsRoutes.hub,
          builder: (context, state) =>
              const Scaffold(body: Text('account-settings-page')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    return router;
  }

  group('showSettingsMenuSheet — capability-aware (RBAC Phase 7K)', () {
    testWidgets(
      'a non-owner (worker/manager) taps Settings tab and lands directly '
      'on Account Settings — no popover appears in between',
      (tester) async {
        final router = await pumpTrigger(tester, isProviderOwner: false);
        expect(router.state.uri.path, '/');

        await tester.tap(find.text('open-settings'));
        await tester.pumpAndSettle();

        // Landed directly on Account Settings — the popover was skipped.
        expect(router.state.uri.path, AccountSettingsRoutes.hub);
        expect(find.text('account-settings-page'), findsOneWidget);
      },
    );

    // NB: no complementary "owner shows popover" test here — the popover
    // uses `PopupMenu` which requires the design_system theme installed
    // in the overlay tree, which this test's minimal harness does not
    // provide. The route-level equivalent ("owner is NOT redirected away
    // from /settings") is asserted in `provider_router_test.dart`, so the
    // owner path is covered structurally; here we only need to prove the
    // non-owner fast path fires exactly once and lands on Account
    // Settings.
  });
}
