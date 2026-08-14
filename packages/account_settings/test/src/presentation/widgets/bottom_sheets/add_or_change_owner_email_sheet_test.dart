// EasyLocalization is not bootstrapped here (see the business-side
// `AddOrChangeEmailSheet` test this mirrors, and `worker_list_item_test.dart`
// for why) — `.tr()` falls back to the raw key, so assertions below match
// against the raw i18n key rather than translated copy.
import 'package:account_settings/src/presentation/widgets/bottom_sheets/add_or_change_owner_email_sheet.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// Covers the visible-inline-error gap: previously `_canContinue` silently
/// gated the Continue button with no on-screen feedback for invalid input.
Future<void> _openSheet(WidgetTester tester) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      builder: (_, _) => MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showAddOrChangeOwnerEmailSheet(context: context),
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

const _invalidEmailErrorKey = 'settings.email_address_invalid_error';

void main() {
  group('AddOrChangeOwnerEmailSheet validation', () {
    testWidgets('no error shown before any input', (tester) async {
      await _openSheet(tester);

      expect(find.text(_invalidEmailErrorKey), findsNothing);
    });

    testWidgets('invalid non-empty input shows the visible error', (
      tester,
    ) async {
      await _openSheet(tester);

      await tester.enterText(find.byType(TextField), 'not-an-email');
      await tester.pumpAndSettle();

      expect(find.text(_invalidEmailErrorKey), findsOneWidget);

      final continueButton = tester.widget<AppButton>(find.byType(AppButton));
      expect(continueButton.onPressed, isNull);
    });

    testWidgets('valid input clears the error and enables Continue', (
      tester,
    ) async {
      await _openSheet(tester);

      await tester.enterText(find.byType(TextField), 'not-an-email');
      await tester.pumpAndSettle();
      expect(find.text(_invalidEmailErrorKey), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'owner@example.com');
      await tester.pumpAndSettle();

      expect(find.text(_invalidEmailErrorKey), findsNothing);

      final continueButton = tester.widget<AppButton>(find.byType(AppButton));
      expect(continueButton.onPressed, isNotNull);
    });
  });
}
