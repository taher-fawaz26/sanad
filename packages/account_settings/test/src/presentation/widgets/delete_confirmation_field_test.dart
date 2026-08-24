// EasyLocalization is not bootstrapped here — `.tr()` falls back to the raw
// key, which is fine since these tests target the field's input/output
// behavior, not its rendered copy.
import 'package:account_settings/src/presentation/widgets/delete_confirmation_field.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester, {
  required ValueChanged<bool> onConfirmedChanged,
  TextDirection direction = TextDirection.ltr,
}) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(400, 800),
      builder: (_, _) => MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Directionality(
            textDirection: direction,
            child: DeleteConfirmationField(
              onConfirmedChanged: onConfirmedChanged,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('empty field never reports confirmed', (tester) async {
    final confirmations = <bool>[];
    await _pump(tester, onConfirmedChanged: confirmations.add);

    // No input at all.
    await tester.pump();

    expect(confirmations, isNot(contains(true)));
  });

  testWidgets('partial text (DEL) does not confirm', (tester) async {
    final confirmations = <bool>[];
    await _pump(tester, onConfirmedChanged: confirmations.add);

    await tester.enterText(find.byType(TextField), 'DEL');
    await tester.pump();

    expect(confirmations, isNot(contains(true)));
  });

  testWidgets('wrong-case text (delete) does not confirm — case-sensitive', (
    tester,
  ) async {
    final confirmations = <bool>[];
    await _pump(tester, onConfirmedChanged: confirmations.add);

    await tester.enterText(find.byType(TextField), 'delete');
    await tester.pump();

    expect(confirmations, isNot(contains(true)));
  });

  testWidgets('exact DELETE reports confirmed once', (tester) async {
    final confirmations = <bool>[];
    await _pump(tester, onConfirmedChanged: confirmations.add);

    await tester.enterText(find.byType(TextField), 'DELETE');
    await tester.pump();

    expect(confirmations.last, isTrue);
  });

  testWidgets('confirmed then edited reports un-confirmed again', (
    tester,
  ) async {
    final confirmations = <bool>[];
    await _pump(tester, onConfirmedChanged: confirmations.add);

    await tester.enterText(find.byType(TextField), 'DELETE');
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'DELET');
    await tester.pump();

    expect(confirmations.last, isFalse);
  });

  testWidgets('clearing the field reports un-confirmed', (tester) async {
    final confirmations = <bool>[];
    await _pump(tester, onConfirmedChanged: confirmations.add);

    await tester.enterText(find.byType(TextField), 'DELETE');
    await tester.pump();
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();

    expect(confirmations.last, isFalse);
  });

  testWidgets('leading/trailing whitespace around DELETE still confirms', (
    tester,
  ) async {
    final confirmations = <bool>[];
    await _pump(tester, onConfirmedChanged: confirmations.add);

    await tester.enterText(find.byType(TextField), '  DELETE  ');
    await tester.pump();

    expect(confirmations.last, isTrue);
  });

  testWidgets('an error is shown for wrong text but not while empty', (
    tester,
  ) async {
    await _pump(tester, onConfirmedChanged: (_) {});

    // Empty → no error surfaced.
    await tester.pump();
    expect(find.text('account_deletion.type_delete_error'), findsNothing);

    // Wrong text → error surfaced.
    await tester.enterText(find.byType(TextField), 'nope');
    await tester.pump();
    expect(find.text('account_deletion.type_delete_error'), findsOneWidget);

    // Exact DELETE → error cleared.
    await tester.enterText(find.byType(TextField), 'DELETE');
    await tester.pump();
    expect(find.text('account_deletion.type_delete_error'), findsNothing);
  });

  testWidgets('works under RTL directionality', (tester) async {
    final confirmations = <bool>[];
    await _pump(
      tester,
      onConfirmedChanged: confirmations.add,
      direction: TextDirection.rtl,
    );

    await tester.enterText(find.byType(TextField), 'DELETE');
    await tester.pump();

    expect(confirmations.last, isTrue);
  });
}
