import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permissions/src/domain/enums/permission_type.dart';
import 'package:permissions/src/presentation/dialogs/permission_rationale_dialog.dart';
import 'package:permissions/src/theme/permission_theme.dart';

const _surfaceSize = Size(390, 844);

/// A nested [Navigator] with two routes — a "hub" beneath and a "current
/// page" on top — mirroring the real app shape this bug reproduces:
/// `GeneralSettingsPage` (`/settings/general`) pushed on top of the
/// Settings-tab hub, both inside a shell-owned navigator that is a
/// *different* Navigator instance from the app's true root (the one
/// `SheetNavigator.push` always targets via `rootNavigator: true`).
///
/// [onTriggerPressed] is invoked with the *current page's* own
/// `BuildContext` — the same shape a real caller passes to
/// `Permissions.ensure(context: ...)`.
class _NestedShellHarness extends StatefulWidget {
  const _NestedShellHarness({required this.onTriggerPressed});

  final void Function(BuildContext pageContext) onTriggerPressed;

  @override
  State<_NestedShellHarness> createState() => _NestedShellHarnessState();
}

class _NestedShellHarnessState extends State<_NestedShellHarness> {
  final navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _pushCurrentPage());
  }

  void _pushCurrentPage() {
    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (pageContext) => Scaffold(
          body: Center(
            child: ElevatedButton(
              key: const Key('trigger'),
              onPressed: () => widget.onTriggerPressed(pageContext),
              child: const Text('trigger'),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (settings) => MaterialPageRoute(
        builder: (_) => const Scaffold(body: Center(child: Text('hub-page'))),
      ),
    );
  }
}

Future<void> _pumpHarness(
  WidgetTester tester,
  void Function(BuildContext pageContext) onTriggerPressed,
) async {
  // flutter_test's default 800×600 surface is too short for the dialog's
  // full default copy (icon + title + rationale text + two full-width
  // buttons) — size the test view like a real phone so nothing overflows.
  tester.view.physicalSize = _surfaceSize * tester.view.devicePixelRatio;
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: _surfaceSize,
      minTextAdapt: true,
      builder: (_, _) => MaterialApp(
        theme: AppTheme.light(),
        home: _NestedShellHarness(onTriggerPressed: onTriggerPressed),
      ),
    ),
  );
  // Let the post-frame callback push the "current page".
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'tapping Allow pops the sheet on the root navigator and resolves true '
    '— it must not pop the caller-side nested navigator instead (which '
    'would incorrectly navigate away from the page that requested the '
    'permission, e.g. back to the Settings hub — SAN-697)',
    (tester) async {
      Future<bool>? shown;
      await _pumpHarness(tester, (pageContext) {
        shown = PermissionRationaleDialog.show(
          context: pageContext,
          permissionType: PermissionType.gallery,
          theme: const PermissionTheme(),
        );
      });

      // Sanity: we're on the pushed "current page", not the hub.
      expect(find.text('hub-page'), findsNothing);
      expect(find.byKey(const Key('trigger')), findsOneWidget);

      await tester.tap(find.byKey(const Key('trigger')));
      await tester.pumpAndSettle();
      expect(find.text('Allow'), findsOneWidget);

      await tester.tap(find.text('Allow'));
      await tester.pumpAndSettle();

      expect(await shown, isTrue);
      // The underlying "current page" must still be mounted — only the
      // sheet should have been popped, not the caller's own route.
      expect(find.byKey(const Key('trigger')), findsOneWidget);
      expect(find.text('hub-page'), findsNothing);
    },
  );

  testWidgets(
    'tapping Not Now pops the sheet and resolves false, leaving the caller '
    'page mounted',
    (tester) async {
      Future<bool>? shown;
      await _pumpHarness(tester, (pageContext) {
        shown = PermissionRationaleDialog.show(
          context: pageContext,
          permissionType: PermissionType.gallery,
          theme: const PermissionTheme(),
        );
      });

      await tester.tap(find.byKey(const Key('trigger')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Not Now'));
      await tester.pumpAndSettle();

      expect(await shown, isFalse);
      expect(find.byKey(const Key('trigger')), findsOneWidget);
    },
  );

  testWidgets(
    'the sheet renders a solid, non-transparent card behind its content',
    (tester) async {
      await _pumpHarness(tester, (pageContext) {
        PermissionRationaleDialog.show(
          context: pageContext,
          permissionType: PermissionType.gallery,
          theme: const PermissionTheme(),
        );
      });

      await tester.tap(find.byKey(const Key('trigger')));
      await tester.pumpAndSettle();

      final material = tester.widget<Material>(
        find
            .ancestor(of: find.text('Allow'), matching: find.byType(Material))
            .first,
      );
      expect(material.color, isNot(Colors.transparent));
      expect(material.color, isNotNull);
    },
  );
}
