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
        home: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}

void main() {
  group('AppSelectSheet singleSelect', () {
    testWidgets('tapping a row immediately pops with that single item', (
      tester,
    ) async {
      // The modal sheet's content can exceed the default (small) test
      // surface — use a realistic device-sized surface instead.
      await tester.binding.setSurfaceSize(const Size(1080, 2400));
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      List<String>? result;

      await _pump(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showAppSelectSheet<String>(
                context: context,
                title: 'Category',
                searchHint: 'Search',
                singleSelect: true,
                getId: (item) => item,
                searchFilter: (item, query) =>
                    item.toLowerCase().contains(query),
                items: const ['Car', 'Home Services'],
                itemBuilder: (context, item, isSelected, onTap) =>
                    AppTableRow(title: item, onTap: onTap),
              );
            },
            child: const Text('Open'),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Car'), findsOneWidget);
      expect(find.text('Home Services'), findsOneWidget);
      // No footer confirm button in single-select mode.
      expect(find.byType(AppButton), findsNothing);

      await tester.tap(find.text('Car'));
      await tester.pumpAndSettle();

      expect(result, ['Car']);
    });
  });
}
