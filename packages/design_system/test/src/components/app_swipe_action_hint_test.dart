import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

late SlidableController _capturedController;

final _oneAction = [
  AppSwipeAction(icon: Icons.edit, semanticLabel: 'Edit', onPressed: () {}),
];

Widget _host({
  required bool enabled,
  required VoidCallback onShown,
  List<AppSwipeAction> actions = const [],
  bool disableAnimations = false,
  bool accessibleNavigation = false,
  TextDirection direction = TextDirection.ltr,
}) {
  return ScreenUtilInit(
    designSize: const Size(360, 800),
    minTextAdapt: true,
    builder: (_, _) => MaterialApp(
      theme: AppTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: disableAnimations,
          accessibleNavigation: accessibleNavigation,
        ),
        child: Directionality(textDirection: direction, child: child!),
      ),
      home: Scaffold(
        body: AppSwipeActionHint(
          enabled: enabled,
          onShown: onShown,
          builder: (context, controller) {
            _capturedController = controller;
            return SizedBox(
              height: 72,
              child: AppSwipeActions(
                controller: controller,
                actions: actions,
                child: const ListTile(title: Text('Row')),
              ),
            );
          },
        ),
      ),
    ),
  );
}

/// Advances the fake clock in small steps rather than one large jump — the
/// hint chains bare `Timer` delays with `AnimationController` animations,
/// and a ticker's elapsed time is sampled from frame timestamps, so a
/// single huge `pump(duration)` can mis-measure an animation that starts
/// partway through it. Small steps keep each animation's own elapsed time
/// accurate.
Future<void> _advance(
  WidgetTester tester,
  Duration total, {
  Duration step = const Duration(milliseconds: 20),
}) async {
  var remaining = total;
  while (remaining > Duration.zero) {
    final thisStep = remaining < step ? remaining : step;
    await tester.pump(thisStep);
    remaining -= thisStep;
  }
}

void main() {
  group('AppSwipeActionHint', () {
    testWidgets(
      'plays once — peeks the end pane, holds, closes, then calls onShown',
      (tester) async {
        var shown = 0;
        await tester.pumpWidget(
          _host(enabled: true, onShown: () => shown++, actions: _oneAction),
        );
        await tester.pump();

        // Still closed during the initial delay (450ms).
        await _advance(tester, const Duration(milliseconds: 100));
        expect(_capturedController.ratio, 0);
        expect(shown, 0);

        // Past initial delay (450) + reveal (300), safely into the 700ms
        // hold — peeked open and holding steady.
        await _advance(tester, const Duration(milliseconds: 700));
        expect(_capturedController.ratio, isNot(0));
        expect(shown, 0);

        // Past the rest of the hold + the 300ms close, with margin — back
        // to closed, hint reported shown.
        await _advance(tester, const Duration(milliseconds: 1000));
        expect(_capturedController.ratio, 0);
        expect(shown, 1);
      },
    );

    testWidgets('never plays when disabled', (tester) async {
      var shown = 0;
      await tester.pumpWidget(
        _host(enabled: false, onShown: () => shown++, actions: _oneAction),
      );
      await tester.pump();
      await _advance(tester, const Duration(seconds: 2));

      expect(_capturedController.ratio, 0);
      expect(shown, 0);
    });

    testWidgets(
      'a real pointer-down mid-hint cancels immediately and reports shown',
      (tester) async {
        var shown = 0;
        await tester.pumpWidget(
          _host(enabled: true, onShown: () => shown++, actions: _oneAction),
        );
        await tester.pump();

        // Into the reveal.
        await _advance(tester, const Duration(milliseconds: 600));
        expect(_capturedController.ratio, isNot(0));

        await tester.tap(find.text('Row'));
        await _advance(tester, const Duration(milliseconds: 300));

        expect(shown, 1);
        expect(_capturedController.ratio, 0);

        // Cancellation must not resume later.
        await _advance(tester, const Duration(seconds: 2));
        expect(shown, 1);
      },
    );

    testWidgets('aborts immediately when the row has no actions to reveal', (
      tester,
    ) async {
      var shown = 0;
      await tester.pumpWidget(_host(enabled: true, onShown: () => shown++));
      await tester.pump();

      expect(shown, 1);
      expect(_capturedController.ratio, 0);
    });

    testWidgets('skips the hint when reduce-motion is enabled', (
      tester,
    ) async {
      var shown = 0;
      await tester.pumpWidget(
        _host(
          enabled: true,
          onShown: () => shown++,
          actions: _oneAction,
          disableAnimations: true,
        ),
      );
      await tester.pump();
      await _advance(tester, const Duration(seconds: 2));

      expect(shown, 1);
      expect(_capturedController.ratio, 0);
    });

    testWidgets('skips the hint when a screen reader is active', (
      tester,
    ) async {
      var shown = 0;
      await tester.pumpWidget(
        _host(
          enabled: true,
          onShown: () => shown++,
          actions: _oneAction,
          accessibleNavigation: true,
        ),
      );
      await tester.pump();
      await _advance(tester, const Duration(seconds: 2));

      expect(shown, 1);
      expect(_capturedController.ratio, 0);
    });

    testWidgets('RTL: peeks the end pane without throwing', (tester) async {
      var shown = 0;
      await tester.pumpWidget(
        _host(
          enabled: true,
          onShown: () => shown++,
          actions: _oneAction,
          direction: TextDirection.rtl,
        ),
      );
      await tester.pump();

      await _advance(tester, const Duration(milliseconds: 800));
      expect(_capturedController.ratio, isNot(0));
      expect(tester.takeException(), isNull);

      await _advance(tester, const Duration(milliseconds: 1000));
      expect(_capturedController.ratio, 0);
      expect(shown, 1);
    });
  });
}
