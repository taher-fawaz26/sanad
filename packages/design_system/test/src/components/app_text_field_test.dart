import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

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

void main() {
  group('AppTextField trailing action', () {
    testWidgets('shows its value with no trailing', (tester) async {
      await _pump(
        tester,
        AppTextField(
          label: 'Name',
          controller: TextEditingController(text: 'Layla Al Mansoori'),
          readOnly: true,
        ),
      );

      expect(find.text('Layla Al Mansoori'), findsOneWidget);
    });

    testWidgets(
      'does not starve its value of width at a realistic phone width '
      '(regression: Align with no widthFactor tried to fill all available '
      'width, leaving 0px for the value — reported as "empty" fields even '
      'though the correct value was present in the tree)',
      (tester) async {
        await _pump(
          tester,
          AppTextField(
            label: 'Name',
            controller: TextEditingController(text: 'Layla Al Mansoori'),
            readOnly: true,
            trailing: const AppFieldTextLinkTrailing(label: 'Change'),
          ),
        );

        final finder = find.text('Layla Al Mansoori');
        expect(finder, findsOneWidget);
        expect(tester.getSize(finder).width, greaterThan(0));
      },
    );
  });
}
