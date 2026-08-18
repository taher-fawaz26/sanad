import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

// ─── Helpers ─────────────────────────────────────────────────────────────────

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      // A generous design size keeps cells small on the default test
      // viewport, so the 6 cells lay out without overflowing.
      designSize: const Size(2000, 3000),
      minTextAdapt: true,
      builder: (_, _) => MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: Center(child: child)),
      ),
    ),
  );
  await tester.pump();
}

/// Taps OTP cell [index] (0-based) and flushes the frame that applies the
/// selection.
Future<void> _tapCell(WidgetTester tester, int index) async {
  await tester.tap(find.byKey(otpCellKey(index)));
  // The tap re-applies the selection in a post-frame callback (to survive
  // focus attachment). `pump()` skips drawing a frame when none is
  // scheduled, so schedule one explicitly to guarantee it runs.
  tester.binding.scheduleFrame();
  await tester.pump();
}

/// The editing state the framework has pushed to the platform text input —
/// i.e. what a real IME sees. This is what makes typing replace a digit
/// rather than append, so it's the assertion that matters most.
Map<String, dynamic> _imeState(WidgetTester tester) =>
    tester.testTextInput.editingState!;

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('AppOtpField tap-to-edit', () {
    testWidgets('tapping a filled digit selects it, not the end of the code', (
      tester,
    ) async {
      final controller = TextEditingController(text: '066555');
      await _pump(tester, AppOtpField(controller: controller));

      await _tapCell(tester, 2);

      expect(
        controller.selection,
        const TextSelection(baseOffset: 2, extentOffset: 3),
      );
    });

    testWidgets('tapping the first digit selects index 0', (tester) async {
      final controller = TextEditingController(text: '066555');
      await _pump(tester, AppOtpField(controller: controller));

      await _tapCell(tester, 0);

      expect(
        controller.selection,
        const TextSelection(baseOffset: 0, extentOffset: 1),
      );
    });

    testWidgets('tapping the last digit selects index 5', (tester) async {
      final controller = TextEditingController(text: '066555');
      await _pump(tester, AppOtpField(controller: controller));

      await _tapCell(tester, 5);

      expect(
        controller.selection,
        const TextSelection(baseOffset: 5, extentOffset: 6),
      );
    });

    testWidgets('every position is independently editable', (tester) async {
      final controller = TextEditingController(text: '066555');
      await _pump(tester, AppOtpField(controller: controller));

      for (final index in [0, 2, 5]) {
        await _tapCell(tester, index);
        expect(
          controller.selection,
          TextSelection(baseOffset: index, extentOffset: index + 1),
          reason: 'tapping cell $index should select exactly that digit',
        );
      }
    });

    testWidgets('tapping past the last typed digit resumes appending at the '
        'end', (tester) async {
      final controller = TextEditingController(text: '066');
      await _pump(tester, AppOtpField(controller: controller));

      await _tapCell(tester, 4);

      expect(controller.selection, const TextSelection.collapsed(offset: 3));
    });
  });

  group('AppOtpField replacement', () {
    testWidgets(
      'the tapped digit is pushed to the platform IME as a selected range, '
      'so the next keystroke replaces it instead of appending',
      (tester) async {
        final controller = TextEditingController(text: '066555');
        await _pump(tester, AppOtpField(controller: controller, autofocus: true));

        await _tapCell(tester, 2);

        // This is the real-device mechanism: the IME composes the next
        // keystroke against this selection.
        expect(_imeState(tester)['text'], '066555');
        expect(_imeState(tester)['selectionBase'], 2);
        expect(_imeState(tester)['selectionExtent'], 3);
      },
    );

    testWidgets('typing over the tapped digit replaces just that digit '
        '(066555 → tap #3 → 9 → 069555)', (tester) async {
      final controller = TextEditingController(text: '066555');
      final changes = <String>[];
      await _pump(
        tester,
        AppOtpField(
          controller: controller,
          autofocus: true,
          onChanged: changes.add,
        ),
      );

      await _tapCell(tester, 2);

      // What an IME sends after replacing the selected range with '9'.
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '069555',
          selection: TextSelection.collapsed(offset: 3),
        ),
      );
      await tester.pump();

      expect(controller.text, '069555');
      expect(changes.last, '069555');
    });

    testWidgets('replacing a digit does not require re-entering the rest', (
      tester,
    ) async {
      final controller = TextEditingController(text: '111111');
      await _pump(
        tester,
        AppOtpField(controller: controller, autofocus: true),
      );

      await _tapCell(tester, 0);
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '911111',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );
      await tester.pump();

      expect(controller.text, '911111');
      expect(controller.text.length, 6, reason: 'no digits were lost');
    });
  });

  group('AppOtpField backspace', () {
    testWidgets('deleting from a mid-string cursor removes the previous digit', (
      tester,
    ) async {
      final controller = TextEditingController(text: '066555');
      await _pump(
        tester,
        AppOtpField(controller: controller, autofocus: true),
      );

      await _tapCell(tester, 2);
      // Backspace over the selected digit clears that digit.
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '06555',
          selection: TextSelection.collapsed(offset: 2),
        ),
      );
      await tester.pump();

      expect(controller.text, '06555');
      expect(controller.selection, const TextSelection.collapsed(offset: 2));
    });

    testWidgets('deleting at the end removes the last digit', (tester) async {
      final controller = TextEditingController(text: '066555');
      await _pump(
        tester,
        AppOtpField(controller: controller, autofocus: true),
      );

      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '06655',
          selection: TextSelection.collapsed(offset: 5),
        ),
      );
      await tester.pump();

      expect(controller.text, '06655');
    });
  });

  group('AppOtpField error state', () {
    testWidgets(
      'an incorrect-code error keeps the typed code and still allows editing '
      'digit #3 directly',
      (tester) async {
        final controller = TextEditingController(text: '066555');
        await _pump(
          tester,
          AppOtpField(
            controller: controller,
            autofocus: true,
            errorText: 'Incorrect verification code',
          ),
        );

        expect(find.text('Incorrect verification code'), findsOneWidget);

        await _tapCell(tester, 2);

        expect(controller.text, '066555');
        expect(
          controller.selection,
          const TextSelection(baseOffset: 2, extentOffset: 3),
        );
      },
    );

    testWidgets(
      'a selection survives an error-state rebuild, and the controller is not '
      'recreated',
      (tester) async {
        final controller = TextEditingController(text: '066555');
        await _pump(
          tester,
          AppOtpField(controller: controller, autofocus: true),
        );

        await _tapCell(tester, 2);
        final selectionBefore = controller.selection;

        // Same controller, new error prop — the Bloc error transition.
        await _pump(
          tester,
          AppOtpField(
            controller: controller,
            autofocus: true,
            errorText: 'Incorrect verification code',
          ),
        );

        expect(controller.selection, selectionBefore);
        expect(controller.text, '066555');
        expect(_imeState(tester)['selectionBase'], 2);
      },
    );
  });

  group('AppOtpField paste', () {
    testWidgets('pasting a full 6-digit code fills every cell and completes', (
      tester,
    ) async {
      final controller = TextEditingController();
      String? completed;
      await _pump(
        tester,
        AppOtpField(
          controller: controller,
          autofocus: true,
          onCompleted: (value) => completed = value,
        ),
      );

      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '123456',
          selection: TextSelection.collapsed(offset: 6),
        ),
      );
      await tester.pump();

      expect(controller.text, '123456');
      expect(completed, '123456');
      expect(find.text('1'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
    });

    testWidgets('a partial paste is accepted without completing', (
      tester,
    ) async {
      final controller = TextEditingController();
      var completedCount = 0;
      await _pump(
        tester,
        AppOtpField(
          controller: controller,
          autofocus: true,
          onCompleted: (_) => completedCount++,
        ),
      );

      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '123',
          selection: TextSelection.collapsed(offset: 3),
        ),
      );
      await tester.pump();

      expect(controller.text, '123');
      expect(completedCount, 0);
    });

    testWidgets('an over-long paste is clamped to the OTP length', (
      tester,
    ) async {
      final controller = TextEditingController();
      await _pump(
        tester,
        AppOtpField(controller: controller, autofocus: true),
      );

      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '1234567890',
          selection: TextSelection.collapsed(offset: 10),
        ),
      );
      await tester.pump();

      expect(controller.text, '123456');
    });

    testWidgets('non-digits are rejected', (tester) async {
      final controller = TextEditingController();
      await _pump(
        tester,
        AppOtpField(controller: controller, autofocus: true),
      );

      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '1a2b3c',
          selection: TextSelection.collapsed(offset: 6),
        ),
      );
      await tester.pump();

      expect(controller.text, '123');
    });
  });

  group('AppOtpField callbacks', () {
    testWidgets('onChanged fires for value changes but not for tap-only '
        'selection changes', (tester) async {
      final controller = TextEditingController(text: '066555');
      final changes = <String>[];
      await _pump(
        tester,
        AppOtpField(
          controller: controller,
          autofocus: true,
          onChanged: changes.add,
        ),
      );

      await _tapCell(tester, 2);
      expect(changes, isEmpty, reason: 'a tap changes selection, not value');

      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '069555',
          selection: TextSelection.collapsed(offset: 3),
        ),
      );
      await tester.pump();

      expect(changes, ['069555']);
    });

    testWidgets('a programmatic controller change is still reported', (
      tester,
    ) async {
      final controller = TextEditingController(text: '111111');
      final changes = <String>[];
      await _pump(
        tester,
        AppOtpField(controller: controller, onChanged: changes.add),
      );

      controller.clear();
      await tester.pump();

      expect(changes, ['']);
    });
  });

  group('AppOtpField autofocus & disabled', () {
    testWidgets('autofocus opens the keyboard on mount', (tester) async {
      final controller = TextEditingController();
      await _pump(
        tester,
        AppOtpField(controller: controller, autofocus: true),
      );

      expect(tester.testTextInput.hasAnyClients, isTrue);
    });

    testWidgets('a disabled field ignores taps entirely', (tester) async {
      final controller = TextEditingController(text: '066555');
      await _pump(
        tester,
        AppOtpField(controller: controller, enabled: false),
      );
      final before = controller.selection;

      await _tapCell(tester, 2);

      expect(controller.selection, before);
    });
  });

  group('AppOtpField form integration', () {
    testWidgets('Form.validate() surfaces the validator message', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController(text: '12');
      await _pump(
        tester,
        Form(
          key: formKey,
          child: AppOtpField(
            controller: controller,
            validator: (value) =>
                (value == null || value.length < 6) ? 'Incomplete code' : null,
          ),
        ),
      );

      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();

      expect(find.text('Incomplete code'), findsOneWidget);
    });

    testWidgets('an explicit errorText takes precedence over the validator', (
      tester,
    ) async {
      final controller = TextEditingController(text: '123456');
      await _pump(
        tester,
        Form(
          child: AppOtpField(
            controller: controller,
            errorText: 'Server says invalid',
            validator: (_) => 'Local message',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Server says invalid'), findsOneWidget);
      expect(find.text('Local message'), findsNothing);
    });
  });

  group('AppOtpField layout', () {
    testWidgets(
      'cells shrink instead of overflowing when the width cannot fit 6 full '
      'cells (regression: a fixed-width Row overflowed by ~257px)',
      (tester) async {
        await _pump(
          tester,
          SizedBox(
            width: 200,
            child: AppOtpField(
              controller: TextEditingController(text: '066555'),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('all six cells are laid out and tappable', (tester) async {
      await _pump(
        tester,
        AppOtpField(controller: TextEditingController(text: '066555')),
      );

      for (var i = 0; i < kDefaultOtpLength; i++) {
        expect(find.byKey(otpCellKey(i)), findsOneWidget);
      }
    });
  });

  group('AppOtpField lifecycle', () {
    testWidgets('works without a caller-supplied controller', (tester) async {
      await _pump(tester, const AppOtpField(autofocus: true));

      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '123456',
          selection: TextSelection.collapsed(offset: 6),
        ),
      );
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('disposing does not touch a caller-owned controller', (
      tester,
    ) async {
      final controller = TextEditingController(text: '123456');
      await _pump(tester, AppOtpField(controller: controller));

      await _pump(tester, const SizedBox.shrink());

      // Would throw if the widget had disposed a controller it doesn't own.
      expect(() => controller.text, returnsNormally);
      controller.dispose();
    });
  });
}
