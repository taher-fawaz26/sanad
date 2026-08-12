import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

// ─── Helpers ─────────────────────────────────────────────────────────────────

/// Reproduces the crash pattern from a real caller (branches'
/// `ContactEditSheet`): a parent owns the [TextEditingController], listens on
/// it with a synchronous `setState`, and mounts [AppPhoneField] with it
/// during the parent's own first build.
class _ParentWithControllerListener extends StatefulWidget {
  const _ParentWithControllerListener({required this.initialPhone});

  final String initialPhone;

  @override
  State<_ParentWithControllerListener> createState() =>
      _ParentWithControllerListenerState();
}

class _ParentWithControllerListenerState
    extends State<_ParentWithControllerListener> {
  late final _controller = TextEditingController(text: widget.initialPhone);

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppPhoneField(label: 'Phone', controller: _controller);
  }
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      builder: (_, _) =>
          MaterialApp(theme: AppTheme.light(), home: Scaffold(body: child)),
    ),
  );
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('AppPhoneField dial-code stripping', () {
    testWidgets(
      'does not re-enter a still-building parent that listens on the '
      "controller (regression: framework's !_dirty assertion)",
      (tester) async {
        // `971501234567` needs stripping to `501234567` — this is the case
        // that used to mutate the controller synchronously in initState and
        // crash when a parent's listener called setState mid-build.
        await _pump(
          tester,
          const _ParentWithControllerListener(initialPhone: '971501234567'),
        );

        expect(tester.takeException(), isNull);

        // The strip is now deferred to a post-frame callback.
        await tester.pump();

        final field = tester.widget<TextField>(find.byType(TextField));
        expect(field.controller!.text, '501234567');
      },
    );

    testWidgets('leaves an already-national value untouched', (tester) async {
      await _pump(
        tester,
        const _ParentWithControllerListener(initialPhone: '501234567'),
      );
      await tester.pump();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, '501234567');
      expect(tester.takeException(), isNull);
    });
  });
}
