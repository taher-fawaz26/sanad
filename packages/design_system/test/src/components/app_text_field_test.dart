import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  TextDirection ambient = TextDirection.ltr,
}) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      builder: (_, _) => MaterialApp(
        theme: AppTheme.light(),
        home: Directionality(
          textDirection: ambient,
          child: Scaffold(body: child),
        ),
      ),
    ),
  );
}

TextDirection _directionOf(WidgetTester tester, Finder finder) {
  return Directionality.of(tester.element(finder));
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

  group('AppTextField isLtr', () {
    testWidgets('forces the input row to LTR under an RTL ambient (Arabic)', (
      tester,
    ) async {
      await _pump(
        tester,
        AppTextField(
          label: 'البريد الإلكتروني',
          controller: TextEditingController(text: 'user@example.com'),
          isLtr: true,
        ),
        ambient: TextDirection.rtl,
      );

      expect(_directionOf(tester, find.byType(TextField)), TextDirection.ltr);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.textDirection, TextDirection.ltr);
    });

    testWidgets('keeps the input row LTR under an LTR ambient (English)', (
      tester,
    ) async {
      await _pump(
        tester,
        AppTextField(
          label: 'Email',
          controller: TextEditingController(text: 'user@example.com'),
          isLtr: true,
        ),
      );

      expect(_directionOf(tester, find.byType(TextField)), TextDirection.ltr);
    });

    testWidgets(
      'prefix icon renders on the visual left (start) of the input under RTL',
      (tester) async {
        await _pump(
          tester,
          AppTextField(
            key: const Key('social'),
            label: 'Facebook',
            controller: TextEditingController(text: 'https://fb.com/x'),
            isLtr: true,
            prefixIcon: const SizedBox(
              key: Key('prefix'),
              width: 20,
              height: 20,
            ),
          ),
          ambient: TextDirection.rtl,
        );

        final prefixCenter = tester.getCenter(find.byKey(const Key('prefix')));
        final fieldCenter = tester.getCenter(find.byType(TextField));
        expect(
          prefixCenter.dx,
          lessThan(fieldCenter.dx),
          reason:
              'Under isLtr, the prefix icon must sit visually on the left, '
              'even when the surrounding locale is RTL.',
        );
      },
    );

    testWidgets(
      'leaves the input row under the ambient direction when isLtr is false '
      '(normal Arabic text stays RTL)',
      (tester) async {
        await _pump(
          tester,
          AppTextField(
            label: 'الاسم',
            controller: TextEditingController(text: 'ليلى المنصوري'),
          ),
          ambient: TextDirection.rtl,
        );

        expect(_directionOf(tester, find.byType(TextField)), TextDirection.rtl);
      },
    );

    testWidgets(
      'default English text-field behavior is unchanged when isLtr is false',
      (tester) async {
        await _pump(
          tester,
          AppTextField(
            label: 'Notes',
            controller: TextEditingController(text: 'hello'),
          ),
        );

        expect(_directionOf(tester, find.byType(TextField)), TextDirection.ltr);
      },
    );
  });
}
