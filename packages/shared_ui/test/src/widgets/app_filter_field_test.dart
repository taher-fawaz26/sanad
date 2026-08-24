import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      builder: (_, _) => MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  group('AppFilterField', () {
    const options = [
      AppFilterOption(value: 'active', label: 'Active'),
      AppFilterOption(value: 'inactive', label: 'Inactive'),
    ];

    testWidgets('shows the placeholder when selectedValue is null', (
      tester,
    ) async {
      await _pump(
        tester,
        AppFilterField<String>(
          placeholder: 'Status',
          options: options,
          onTap: () {},
        ),
      );

      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Active'), findsNothing);
    });

    testWidgets(
      'shows the placeholder when selectedValue matches no option '
      '(caller cleared it or the value is unknown)',
      (tester) async {
        await _pump(
          tester,
          AppFilterField<String>(
            placeholder: 'Status',
            options: options,
            selectedValue: 'archived',
            onTap: () {},
          ),
        );

        expect(find.text('Status'), findsOneWidget);
      },
    );

    testWidgets('shows the matching option\'s label when selected', (
      tester,
    ) async {
      await _pump(
        tester,
        AppFilterField<String>(
          placeholder: 'Status',
          options: options,
          selectedValue: 'inactive',
          onTap: () {},
        ),
      );

      expect(find.text('Inactive'), findsOneWidget);
      expect(find.text('Status'), findsNothing);
    });

    testWidgets('tapping the cell invokes onTap', (tester) async {
      var tapped = false;
      await _pump(
        tester,
        AppFilterField<String>(
          placeholder: 'Status',
          options: options,
          onTap: () => tapped = true,
        ),
      );

      await tester.tap(find.byType(InkWell));
      expect(tapped, isTrue);
    });

    testWidgets('disabled cell does not invoke onTap when tapped', (
      tester,
    ) async {
      var tapped = false;
      await _pump(
        tester,
        AppFilterField<String>(
          placeholder: 'Status',
          options: options,
          enabled: false,
          onTap: () => tapped = true,
        ),
      );

      await tester.tap(find.byType(InkWell));
      expect(tapped, isFalse);
    });

    testWidgets('is generic over any value type, not just String', (
      tester,
    ) async {
      await _pump(
        tester,
        AppFilterField<int>(
          placeholder: 'Type',
          options: const [
            AppFilterOption(value: 1, label: 'Worker'),
            AppFilterOption(value: 2, label: 'Manager'),
          ],
          selectedValue: 2,
          onTap: () {},
        ),
      );

      expect(find.text('Manager'), findsOneWidget);
    });
  });
}
