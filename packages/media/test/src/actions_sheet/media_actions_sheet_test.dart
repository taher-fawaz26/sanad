import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media/src/actions_sheet/media_actions_sheet.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

const _surfaceSize = Size(390, 844);

Future<void> _pump(WidgetTester tester, Widget child) {
  // flutter_test's default 800×600 surface doesn't match `designSize`
  // below, inflating ScreenUtil's scale factor well past 1x and overflowing
  // the action rows — size the test view like a real phone instead.
  tester.view.physicalSize = _surfaceSize * tester.view.devicePixelRatio;
  addTearDown(tester.view.resetPhysicalSize);

  return tester.pumpWidget(
    ScreenUtilInit(
      designSize: _surfaceSize,
      minTextAdapt: true,
      builder: (_, _) => MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'the pushed sheet route never morphs to fullscreen (SAN-698) — every '
    'row in this sheet pops it immediately and the caller always proceeds '
    'to something else next (permission prompt, confirmation sheet, editor '
    'page); if this were left true, a route pushed in that handoff — before '
    'this sheet finishes its own exit transition/finalizeRoute, since '
    'Route.didPop resolves the awaited Future synchronously, well ahead of '
    'the animation — would make this still-present sheet morph to '
    'fullscreen while simultaneously reversing closed, corrupting the next '
    "sheet's rendering (e.g. Remove-photo confirmation losing its solid "
    'card background)',
    (tester) async {
      await _pump(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              MediaActionsSheet.show(
                context,
                title: 'Edit Photo',
                hasMedia: true,
              );
            },
            child: const Text('open'),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pump();

      final pushedRoute =
          ModalRoute.of(tester.element(find.byType(MediaActionsSheet)))!
              as ModalSheetRoute<dynamic>;

      expect(pushedRoute.sheetSettings.expandPreviousToFullscreen, isFalse);
    },
  );

  testWidgets('shows View/Remove rows only when media exists', (
    tester,
  ) async {
    await _pump(
      tester,
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () {
            MediaActionsSheet.show(
              context,
              title: 'Edit Photo',
              hasMedia: false,
            );
          },
          child: const Text('open'),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.visibility_outlined), findsNothing);
    expect(find.byIcon(Icons.delete_outline), findsNothing);
    expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget);
  });

  testWidgets('choosing Remove pops the sheet with MediaAction.remove', (
    tester,
  ) async {
    MediaAction? result;

    await _pump(
      tester,
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            result = await MediaActionsSheet.show(
              context,
              title: 'Edit Photo',
              hasMedia: true,
            );
          },
          child: const Text('open'),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(result, MediaAction.remove);
  });
}
