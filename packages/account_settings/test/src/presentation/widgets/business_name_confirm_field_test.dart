// EasyLocalization is not bootstrapped here — `.tr()` falls back to the raw
// key, which is fine since these tests target the field's input/output
// behavior, not its rendered copy.
import 'package:account_settings/src/presentation/widgets/business_name_confirm_field.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester, {
  required String businessName,
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
            child: BusinessNameConfirmField(
              businessName: businessName,
              onConfirmedChanged: onConfirmedChanged,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('typing the wrong name never reports confirmed', (
    tester,
  ) async {
    final confirmations = <bool>[];
    await _pump(
      tester,
      businessName: 'Acme LLC',
      onConfirmedChanged: confirmations.add,
    );

    await tester.enterText(find.byType(TextField), 'Acme');
    await tester.pump();

    expect(confirmations, isNot(contains(true)));
  });

  testWidgets('typing the exact name reports confirmed once', (tester) async {
    final confirmations = <bool>[];
    await _pump(
      tester,
      businessName: 'Acme LLC',
      onConfirmedChanged: confirmations.add,
    );

    await tester.enterText(find.byType(TextField), 'Acme LLC');
    await tester.pump();

    expect(confirmations.last, isTrue);
  });

  testWidgets('a match followed by an edit reports un-confirmed again', (
    tester,
  ) async {
    final confirmations = <bool>[];
    await _pump(
      tester,
      businessName: 'Acme LLC',
      onConfirmedChanged: confirmations.add,
    );

    await tester.enterText(find.byType(TextField), 'Acme LLC');
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Acme LL');
    await tester.pump();

    expect(confirmations.last, isFalse);
  });

  testWidgets('leading/trailing whitespace is trimmed before comparing', (
    tester,
  ) async {
    final confirmations = <bool>[];
    await _pump(
      tester,
      businessName: 'Acme LLC',
      onConfirmedChanged: confirmations.add,
    );

    await tester.enterText(find.byType(TextField), '  Acme LLC  ');
    await tester.pump();

    expect(confirmations.last, isTrue);
  });

  testWidgets('works under RTL directionality with an Arabic business name', (
    tester,
  ) async {
    final confirmations = <bool>[];
    await _pump(
      tester,
      businessName: 'شركة أكمي',
      onConfirmedChanged: confirmations.add,
      direction: TextDirection.rtl,
    );

    await tester.enterText(find.byType(TextField), 'شركة أكمي');
    await tester.pump();

    expect(confirmations.last, isTrue);
  });
}
