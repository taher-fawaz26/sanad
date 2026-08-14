// EasyLocalization is not bootstrapped here (see the `AddOrChangeEmailSheet`
// / `AddOrChangePhoneSheet` tests and `worker_list_item_test.dart` for why)
// — `.tr()` falls back to the raw key, so assertions below match against the
// raw i18n keys rather than translated copy.
import 'package:account_settings/src/presentation/widgets/bottom_sheets/edit_name_sheet.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// Covers the missing-length-validation gap: `_submit()` previously only
/// checked for an empty name, with no length bound matching the backend's
/// `UpdateAccountSettingsDto.name` (minLength 2, maxLength 255).
const _surfaceSize = Size(600, 2000);

Future<void> _openSheet(WidgetTester tester, {String? initialName}) async {
  // The sheet's action-sheet body isn't internally scrollable, so the test
  // surface must be tall enough for title + field + error + footer to fit
  // within the route's `maxHeightFactor` (0.92) of the reported view size —
  // set both the binding surface size and the underlying view's physical
  // size/devicePixelRatio (mirrors `add_service_form_body_test.dart`) so the
  // sheet route's `MediaQuery.sizeOf(context).height` reflects it.
  await tester.binding.setSurfaceSize(_surfaceSize);
  tester.view.physicalSize = _surfaceSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.binding.setSurfaceSize(null);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: _surfaceSize,
      minTextAdapt: true,
      builder: (_, _) => MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showEditNameSheet(
                context: context,
                initialName: initialName,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

const _requiredErrorKey = 'settings.name_required_error';
const _lengthErrorKey = 'validation.length_range';
const _saveButtonKey = 'common.save';

void main() {
  group('EditNameSheet validation', () {
    testWidgets('empty name shows the required error on Save', (
      tester,
    ) async {
      await _openSheet(tester);

      await tester.tap(find.text(_saveButtonKey));
      await tester.pumpAndSettle();

      expect(find.text(_requiredErrorKey), findsOneWidget);
      expect(find.text(_lengthErrorKey), findsNothing);
    });

    testWidgets('1 character shows the length error on Save', (
      tester,
    ) async {
      await _openSheet(tester);

      await tester.enterText(find.byType(TextField), 'A');
      await tester.tap(find.text(_saveButtonKey));
      await tester.pumpAndSettle();

      expect(find.text(_lengthErrorKey), findsOneWidget);
      expect(find.text(_requiredErrorKey), findsNothing);
    });

    testWidgets('256 characters shows the length error on Save', (
      tester,
    ) async {
      await _openSheet(tester);

      await tester.enterText(find.byType(TextField), 'a' * 256);
      await tester.tap(find.text(_saveButtonKey));
      await tester.pumpAndSettle();

      expect(find.text(_lengthErrorKey), findsOneWidget);
    });

    testWidgets('2 characters passes with no error', (tester) async {
      await _openSheet(tester);

      await tester.enterText(find.byType(TextField), 'Al');
      await tester.tap(find.text(_saveButtonKey));
      await tester.pumpAndSettle();

      expect(find.text(_lengthErrorKey), findsNothing);
      expect(find.text(_requiredErrorKey), findsNothing);
    });

    testWidgets('255 characters passes with no error', (tester) async {
      await _openSheet(tester);

      await tester.enterText(find.byType(TextField), 'a' * 255);
      await tester.tap(find.text(_saveButtonKey));
      await tester.pumpAndSettle();

      expect(find.text(_lengthErrorKey), findsNothing);
    });

    testWidgets(
      'typing after an error clears it, matching the existing '
      'onChanged-resets-_errorText behavior',
      (tester) async {
        await _openSheet(tester);

        await tester.tap(find.text(_saveButtonKey));
        await tester.pumpAndSettle();
        expect(find.text(_requiredErrorKey), findsOneWidget);

        await tester.enterText(find.byType(TextField), 'Valid Name');
        await tester.pumpAndSettle();

        expect(find.text(_requiredErrorKey), findsNothing);
      },
    );
  });
}
