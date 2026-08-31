import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  TextDirection direction = TextDirection.rtl,
}) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      builder: (_, _) => MaterialApp(
        theme: AppTheme.light(),
        home: Directionality(
          textDirection: direction,
          child: Scaffold(body: child),
        ),
      ),
    ),
  );
}

void main() {
  // U+2066 LEFT-TO-RIGHT ISOLATE … U+2069 POP DIRECTIONAL ISOLATE.
  String isolated(String v) => '\u{2066}$v\u{2069}';

  group('AppGroupedKeyValueList', () {
    testWidgets(
      'an isLtr value is wrapped in an LTR isolate so a `+`-prefixed phone '
      'reads correctly under RTL (SAN-775)',
      (tester) async {
        await _pump(
          tester,
          const AppGroupedKeyValueList(
            items: [
              GroupedKeyValueItem(
                title: 'Phone',
                value: '+971585555255',
                isLtr: true,
              ),
            ],
          ),
        );

        expect(find.text(isolated('+971585555255')), findsOneWidget);
        // The raw, un-isolated value must NOT be what gets rendered.
        expect(find.text('+971585555255'), findsNothing);
      },
    );

    testWidgets('a non-LTR value is rendered verbatim (no isolate)', (
      tester,
    ) async {
      await _pump(
        tester,
        const AppGroupedKeyValueList(
          items: [
            GroupedKeyValueItem(title: 'City', value: 'Dubai'),
          ],
        ),
      );

      expect(find.text('Dubai'), findsOneWidget);
      expect(find.text(isolated('Dubai')), findsNothing);
    });
  });

  group('AppKeyValueCard', () {
    testWidgets('isLtr wraps the value in an LTR isolate', (tester) async {
      await _pump(
        tester,
        const AppKeyValueCard(
          title: 'Phone',
          value: '+971585555255',
          isLtr: true,
        ),
      );

      expect(find.text(isolated('+971585555255')), findsOneWidget);
    });
  });
}
