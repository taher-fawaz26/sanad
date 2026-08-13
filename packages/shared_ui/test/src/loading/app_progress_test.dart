import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

Future<void> _pump(WidgetTester tester, {required Widget home}) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      builder: (_, _) => MaterialApp(theme: AppTheme.light(), home: home),
    ),
  );
}

/// A host that exposes its context so tests can drive [AppProgress] directly.
class _Host extends StatelessWidget {
  const _Host({required this.onReady});
  final void Function(BuildContext context) onReady;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => onReady(context),
          child: const Text('go'),
        ),
      ),
    );
  }
}

void main() {
  group('AppProgress', () {
    tearDown(AppProgress.reset);

    testWidgets('show renders a non-dismissible dialog with the title', (
      tester,
    ) async {
      await _pump(
        tester,
        home: _Host(
          onReady: (context) =>
              AppProgress.show(context, title: 'Saving changes'),
        ),
      );

      await tester.tap(find.text('go'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(AppProgressDialog), findsOneWidget);
      expect(find.text('Saving changes'), findsOneWidget);
      expect(AppProgress.isShown, isTrue);

      // Tapping the barrier must NOT dismiss it.
      await tester.tapAt(const Offset(10, 10));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(AppProgressDialog), findsOneWidget);

      AppProgress.dismiss();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    });

    testWidgets('duplicate show calls keep a single dialog', (tester) async {
      await _pump(
        tester,
        home: _Host(
          onReady: (context) {
            AppProgress.show(context, title: 'Saving');
            AppProgress.show(context, title: 'Saving again');
          },
        ),
      );

      await tester.tap(find.text('go'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(AppProgressDialog), findsOneWidget);
      expect(find.text('Saving'), findsOneWidget);
      expect(find.text('Saving again'), findsNothing);

      AppProgress.dismiss();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    });

    testWidgets('dismiss removes the dialog exactly once', (tester) async {
      late BuildContext ctx;
      await _pump(
        tester,
        home: _Host(
          onReady: (context) {
            ctx = context;
            AppProgress.show(context, title: 'Saving');
          },
        ),
      );

      await tester.tap(find.text('go'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(AppProgressDialog), findsOneWidget);

      AppProgress.dismiss();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(AppProgressDialog), findsNothing);
      expect(AppProgress.isShown, isFalse);

      // Second dismiss is a safe no-op.
      AppProgress.dismiss();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
      expect(ctx.mounted, isTrue);
    });

    testWidgets('dismiss while hidden is a safe no-op', (tester) async {
      await _pump(
        tester,
        home: const _Host(onReady: _noop),
      );

      AppProgress.dismiss();
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(AppProgress.isShown, isFalse);
    });
  });
}

void _noop(BuildContext _) {}
