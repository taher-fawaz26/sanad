import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/widgets/bottom_sheets/add_or_change_phone_sheet.dart';

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
              onPressed: () => showAddOrChangePhoneSheet(context: context),
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

const _invalidPhoneErrorKey = 'settings.phone_number_invalid_error';

void main() {
  group('AddOrChangePhoneSheet validation', () {
    testWidgets('no error shown before any input', (tester) async {
      await _openSheet(tester);

      expect(find.text(_invalidPhoneErrorKey), findsNothing);
    });

    testWidgets('invalid non-empty input shows the visible error', (
      tester,
    ) async {
      await _openSheet(tester);

      // Too short to be a valid UAE mobile/landline number.
      await tester.enterText(find.byType(TextField), '123');
      await tester.pumpAndSettle();

      expect(find.text(_invalidPhoneErrorKey), findsOneWidget);

      final continueButton = tester.widget<AppButton>(find.byType(AppButton));
      expect(continueButton.onPressed, isNull);
    });

    testWidgets('valid input clears the error and enables Continue', (
      tester,
    ) async {
      await _openSheet(tester);

      await tester.enterText(find.byType(TextField), '123');
      await tester.pumpAndSettle();
      expect(find.text(_invalidPhoneErrorKey), findsOneWidget);

      await tester.enterText(find.byType(TextField), '501234567');
      await tester.pumpAndSettle();

      expect(find.text(_invalidPhoneErrorKey), findsNothing);

      final continueButton = tester.widget<AppButton>(find.byType(AppButton));
      expect(continueButton.onPressed, isNotNull);
    });
  });
}
