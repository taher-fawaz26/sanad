import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:services/src/presentation/widgets/services_filter_bar.dart';

// No EasyLocalization bootstrap — see service_list_item_test.dart's note.
// `.tr()` falls back to the raw key, so assertions below match on the key
// itself.

const _surfaceSize = Size(390, 844);

Future<void> _pump(WidgetTester tester, ServicesFilterBar bar) async {
  await tester.binding.setSurfaceSize(_surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: _surfaceSize,
      minTextAdapt: true,
      builder: (_, _) => MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: bar),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets(
    'tapping the Status dropdown invokes onStatusTap',
    (tester) async {
      var tapped = false;
      await _pump(
        tester,
        ServicesFilterBar(onStatusTap: () => tapped = true),
      );

      await tester.tap(find.text('services.filter_status'));

      expect(tapped, isTrue);
    },
  );

  testWidgets(
    'statusLabel overrides the default "Status" placeholder',
    (tester) async {
      await _pump(tester, const ServicesFilterBar(statusLabel: 'Active'));

      expect(find.text('Active'), findsOneWidget);
      expect(find.text('services.filter_status'), findsNothing);
    },
  );

  testWidgets(
    'the Type dropdown renders but stays inert when onTypeTap is unset',
    (tester) async {
      await _pump(tester, const ServicesFilterBar());

      // Present — Type must never be removed even though it isn't wired.
      expect(find.text('services.filter_type'), findsOneWidget);

      // Tapping it is a no-op (no callback provided): the disabled InkWell
      // absorbs the tap without throwing and without needing a callback to
      // assert against.
      await tester.tap(find.text('services.filter_type'));
      await tester.pump();
    },
  );
}
