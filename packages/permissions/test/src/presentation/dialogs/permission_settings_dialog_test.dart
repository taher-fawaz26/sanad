import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permissions/src/domain/enums/permission_type.dart';
import 'package:permissions/src/presentation/dialogs/permission_settings_dialog.dart';
import 'package:permissions/src/theme/permission_theme.dart';

const _surfaceSize = Size(390, 844);

/// See the matching harness in `permission_rationale_dialog_test.dart` —
/// same nested-navigator shape, reproducing the real app's shell-nested
/// page sitting on a *different* Navigator instance than the app's true
/// root (the one `SheetNavigator.push` always targets).
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
  // full default copy (icon + title + settings text + two full-width
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
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'tapping Cancel pops the sheet on the root navigator without touching '
    'the caller-side nested navigator (SAN-697 — same class of bug as '
    'PermissionRationaleDialog)',
    (tester) async {
      var opened = false;
      await _pumpHarness(tester, (pageContext) {
        opened = true;
        PermissionSettingsDialog.show(
          context: pageContext,
          permissionType: PermissionType.gallery,
          theme: const PermissionTheme(),
          onOpenSettings: () async => true,
        );
      });

      expect(find.text('hub-page'), findsNothing);
      expect(find.byKey(const Key('trigger')), findsOneWidget);

      await tester.tap(find.byKey(const Key('trigger')));
      await tester.pumpAndSettle();
      expect(opened, isTrue);
      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // The underlying "current page" must still be mounted — only the
      // sheet should have been popped.
      expect(find.byKey(const Key('trigger')), findsOneWidget);
      expect(find.text('hub-page'), findsNothing);
    },
  );

  testWidgets(
    'tapping Open Settings pops the sheet and invokes onOpenSettings, '
    'leaving the caller page mounted',
    (tester) async {
      var openSettingsCalled = false;
      await _pumpHarness(tester, (pageContext) {
        PermissionSettingsDialog.show(
          context: pageContext,
          permissionType: PermissionType.gallery,
          theme: const PermissionTheme(),
          onOpenSettings: () async {
            openSettingsCalled = true;
            return true;
          },
        );
      });

      await tester.tap(find.byKey(const Key('trigger')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      expect(openSettingsCalled, isTrue);
      expect(find.byKey(const Key('trigger')), findsOneWidget);
    },
  );
}
