import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget home) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      builder: (_, _) => MaterialApp(theme: AppTheme.light(), home: home),
    ),
  );
}

/// Opens a modal bottom sheet whose body triggers [onTrigger] with the sheet's
/// own context — the exact scenario the location picker runs in.
Widget _sheetHost(void Function(BuildContext sheetContext) onTrigger) {
  return Builder(
    builder: (context) => Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            builder: (sheetContext) => SizedBox(
              height: 400,
              child: Center(
                child: ElevatedButton(
                  onPressed: () => onTrigger(sheetContext),
                  child: const Text('trigger'),
                ),
              ),
            ),
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );
}

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

/// The effective (DefaultTextStyle-merged) style the [text] actually renders
/// with — this is where the WidgetsApp "no Material" underline would show up.
TextStyle _renderedStyleOf(WidgetTester tester, String text) {
  final richText = tester.widget<RichText>(
    find.descendant(of: find.text(text), matching: find.byType(RichText)),
  );
  return (richText.text as TextSpan).style!;
}

void main() {
  // Reset the module-level active notification between tests.
  tearDown(dismissAppOverlayNotification);

  group('showAppOverlayNotification', () {
    testWidgets('renders while a modal bottom sheet stays open', (
      tester,
    ) async {
      await _pump(
        tester,
        _sheetHost(
          (ctx) => showAppOverlayNotification(
            context: ctx,
            title: 'Location services are off',
          ),
        ),
      );

      await _openSheet(tester);
      expect(find.text('trigger'), findsOneWidget); // sheet is open

      await tester.tap(find.text('trigger'));
      await tester.pump(); // insert overlay entry
      await tester.pump(const Duration(milliseconds: 250)); // slide-in

      // The notification is visible AND the sheet is still open.
      expect(find.text('Location services are off'), findsOneWidget);
      expect(find.text('trigger'), findsOneWidget);

      // Cancel the pending auto-dismiss timer before the test ends.
      dismissAppOverlayNotification();
      await tester.pump();
    });

    testWidgets('a second call replaces the first — no stacking', (
      tester,
    ) async {
      await _pump(
        tester,
        _sheetHost((ctx) {
          showAppOverlayNotification(context: ctx, title: 'First error');
          showAppOverlayNotification(context: ctx, title: 'Second error');
        }),
      );

      await _openSheet(tester);
      await tester.tap(find.text('trigger'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('First error'), findsNothing);
      expect(find.text('Second error'), findsOneWidget);

      dismissAppOverlayNotification();
      await tester.pump();
    });

    testWidgets('tapping the action invokes the callback and dismisses', (
      tester,
    ) async {
      var actioned = false;
      await _pump(
        tester,
        _sheetHost(
          (ctx) => showAppOverlayNotification(
            context: ctx,
            title: 'Permission denied',
            action: AppSnackbarAction.text,
            actionLabel: 'Retry',
            onAction: () => actioned = true,
          ),
        ),
      );

      await _openSheet(tester);
      await tester.tap(find.text('trigger'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(actioned, isTrue);
      expect(find.text('Permission denied'), findsNothing);
    });

    testWidgets('auto-dismisses after its duration', (tester) async {
      await _pump(
        tester,
        _sheetHost(
          (ctx) => showAppOverlayNotification(
            context: ctx,
            title: 'Network error',
            duration: const Duration(seconds: 2),
          ),
        ),
      );

      await _openSheet(tester);
      await tester.tap(find.text('trigger'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Network error'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      expect(find.text('Network error'), findsNothing);
    });

    testWidgets(
      'message text renders with no underline and inside a Material — the '
      'regression was the WidgetsApp "no Material" error style',
      (tester) async {
        await _pump(
          tester,
          _sheetHost(
            (ctx) => showAppOverlayNotification(
              context: ctx,
              title: 'Location services are off',
              action: AppSnackbarAction.text,
              actionLabel: 'Open settings',
              onAction: () {},
            ),
          ),
        );

        await _openSheet(tester);
        await tester.tap(find.text('trigger'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));

        // The notification must live inside a Material (restores the theme's
        // DefaultTextStyle over the WidgetsApp error style).
        expect(
          find.ancestor(
            of: find.byType(AppSnackbar),
            matching: find.byType(Material),
          ),
          findsWidgets,
        );

        // Neither the message nor the action is underlined.
        final titleStyle = _renderedStyleOf(
          tester,
          'Location services are off',
        );
        final actionStyle = _renderedStyleOf(tester, 'Open settings');
        expect(
          titleStyle.decoration ?? TextDecoration.none,
          TextDecoration.none,
        );
        expect(
          actionStyle.decoration ?? TextDecoration.none,
          TextDecoration.none,
        );

        dismissAppOverlayNotification();
        await tester.pump();
      },
    );

    testWidgets(
      'title typography matches AppSnackbar rendered inside a Scaffold',
      (tester) async {
        // Reference: the same AppSnackbar inside a normal Scaffold Material.
        await _pump(
          tester,
          const Scaffold(
            body: Center(
              child: AppSnackbar(title: 'Ref', color: AppSnackbarColor.error),
            ),
          ),
        );
        await tester.pump();
        final reference = _renderedStyleOf(tester, 'Ref');

        // Overlay: same AppSnackbar via the top notification, above a sheet.
        await _pump(
          tester,
          _sheetHost(
            (ctx) => showAppOverlayNotification(context: ctx, title: 'Ref'),
          ),
        );
        await _openSheet(tester);
        await tester.tap(find.text('trigger'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));
        final overlay = _renderedStyleOf(tester, 'Ref');

        expect(overlay.fontSize, reference.fontSize);
        expect(overlay.fontWeight, reference.fontWeight);
        expect(overlay.color, reference.color);
        expect(overlay.decoration, reference.decoration);

        dismissAppOverlayNotification();
        await tester.pump();
      },
    );

    testWidgets('dismissAppOverlayNotification removes it immediately', (
      tester,
    ) async {
      await _pump(
        tester,
        _sheetHost(
          (ctx) => showAppOverlayNotification(
            context: ctx,
            title: 'Outside the UAE',
          ),
        ),
      );

      await _openSheet(tester);
      await tester.tap(find.text('trigger'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Outside the UAE'), findsOneWidget);

      dismissAppOverlayNotification();
      await tester.pump();
      expect(find.text('Outside the UAE'), findsNothing);
    });
  });
}
