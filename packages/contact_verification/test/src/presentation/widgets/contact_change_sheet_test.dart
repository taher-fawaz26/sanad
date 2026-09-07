// EasyLocalization is not bootstrapped here (see the sheet wrapper tests this
// mirrors) — `.tr()` falls back to the raw key, so any copy assertion below
// matches the raw i18n key rather than translated text.
import 'package:contact_verification/contact_verification.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/src/localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart' hide VerificationResult;

/// Opens the sheet with [initialValue] standing in for the contact already on
/// file. Nothing here taps Continue, so the DI-resolved use cases the submit
/// path needs are never constructed.
Future<void> _openSheet(
  WidgetTester tester, {
  required ContactField field,
  required VerificationPurpose purpose,
  String? initialValue,
}) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      builder: (_, _) => MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showContactChangeSheet(
                context: context,
                field: field,
                purpose: purpose,
                initialValue: initialValue,
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

bool _continueEnabled(WidgetTester tester) =>
    tester.widget<AppButton>(find.byType(AppButton)).onPressed != null;

Future<void> _type(WidgetTester tester, String value) async {
  await tester.enterText(find.byType(TextField), value);
  await tester.pumpAndSettle();
}

void main() {
  // Continue must require BOTH "changed" and "valid". Gating on validity
  // alone left the button live the instant the (prefilled) sheet opened, so
  // tapping it sent `/contact-verification/request` for the value already on
  // file — which the backend answers 409 "already set".
  group('ContactChangeSheet — Continue gating (email)', () {
    const current = 'owner@example.com';

    Future<void> open(WidgetTester tester, {String? initialValue = current}) =>
        _openSheet(
          tester,
          field: ContactField.email,
          purpose: VerificationPurpose.changeOwnerEmail,
          initialValue: initialValue,
        );

    testWidgets('disabled on open, with the current value prefilled', (
      tester,
    ) async {
      await open(tester);

      expect(find.text(current), findsOneWidget);
      expect(_continueEnabled(tester), isFalse);
    });

    testWidgets('disabled when the value is retyped unchanged', (tester) async {
      await open(tester);
      await _type(tester, current);

      expect(_continueEnabled(tester), isFalse);
    });

    testWidgets('disabled for a case/whitespace-only edit', (tester) async {
      await open(tester);
      await _type(tester, '  Owner@Example.COM  ');

      expect(_continueEnabled(tester), isFalse);
      expect(
        find.text('settings.email_address_invalid_error'),
        findsNothing,
        reason: 'unchanged is not an error — the disabled button is the signal',
      );
    });

    testWidgets('disabled when cleared', (tester) async {
      await open(tester);
      await _type(tester, '');

      expect(_continueEnabled(tester), isFalse);
    });

    testWidgets('disabled for a changed but invalid value', (tester) async {
      await open(tester);
      await _type(tester, 'not-an-email');

      expect(_continueEnabled(tester), isFalse);
      expect(find.text('settings.email_address_invalid_error'), findsOneWidget);
    });

    testWidgets('enabled for a changed, valid value', (tester) async {
      await open(tester);
      await _type(tester, 'new.owner@example.com');

      expect(_continueEnabled(tester), isTrue);
    });

    testWidgets('add flow: any valid value is a change', (tester) async {
      await open(tester, initialValue: null);
      await _type(tester, 'first@example.com');

      expect(_continueEnabled(tester), isTrue);
    });
  });

  group('ContactChangeSheet — Continue gating (phone)', () {
    // Stored E.164; the field shows the national form.
    const current = '+971501234567';

    Future<void> open(WidgetTester tester, {String? initialValue = current}) =>
        _openSheet(
          tester,
          field: ContactField.phone,
          purpose: VerificationPurpose.changeBusinessPhone,
          initialValue: initialValue,
        );

    testWidgets('disabled on open, with the national form prefilled', (
      tester,
    ) async {
      await open(tester);

      expect(find.text('501234567'), findsOneWidget);
      expect(_continueEnabled(tester), isFalse);
    });

    // The comparison is on the normalized number, so re-entering the same
    // subscriber in another notation is not a change.
    for (final notation in const ['501234567', '0501234567', '971501234567']) {
      testWidgets('disabled for the same number written as $notation', (
        tester,
      ) async {
        await open(tester);
        await _type(tester, notation);

        expect(_continueEnabled(tester), isFalse);
      });
    }

    testWidgets('disabled when cleared', (tester) async {
      await open(tester);
      await _type(tester, '');

      expect(_continueEnabled(tester), isFalse);
    });

    testWidgets('disabled for a changed but invalid number', (tester) async {
      await open(tester);
      await _type(tester, '12345');

      expect(_continueEnabled(tester), isFalse);
      expect(find.text('settings.phone_number_invalid_error'), findsOneWidget);
    });

    testWidgets('enabled for a changed, valid number', (tester) async {
      await open(tester);
      await _type(tester, '509876543');

      expect(_continueEnabled(tester), isTrue);
    });

    testWidgets('add flow: any valid number is a change', (tester) async {
      await open(tester, initialValue: null);
      await _type(tester, '501234567');

      expect(_continueEnabled(tester), isTrue);
    });
  });

  // The flow must OPEN a session before asking about it. Reading
  // `/resend-info` first and letting its answer decide whether to send is the
  // bug this whole change exists to fix, so "request was called" is asserted
  // directly, per purpose.
  group('ContactChangeSheet — Continue opens a verification session', () {
    late _MockRequestUseCase requestUseCase;
    late _MockResendInfoUseCase resendInfoUseCase;

    setUpAll(() {
      Localization.load(const Locale('en', 'US'));
      registerFallbackValue(
        const RequestVerificationParams(
          purpose: VerificationPurpose.changeOwnerEmail,
          target: 'x@y.com',
        ),
      );
      registerFallbackValue(
        const ResendInfoParams(purpose: VerificationPurpose.changeOwnerEmail),
      );
      registerFallbackValue(
        const ResendVerificationParams(
          purpose: VerificationPurpose.changeOwnerEmail,
        ),
      );
      registerFallbackValue(
        const VerifyContactParams(
          purpose: VerificationPurpose.changeOwnerEmail,
          code: '000000',
        ),
      );
    });

    setUp(() {
      requestUseCase = _MockRequestUseCase();
      resendInfoUseCase = _MockResendInfoUseCase();

      when(() => requestUseCase(any())).thenAnswer(
        (_) => TaskEither.right(const VerificationDispatch(message: 'sent')),
      );
      // Exactly what the backend answers before a session exists.
      when(() => resendInfoUseCase(any())).thenAnswer(
        (_) => TaskEither.right(
          const VerificationResendInfo(
            canResend: false,
            remainingSeconds: 0,
            attemptsLeft: 0,
          ),
        ),
      );

      sl
        ..registerSingleton<RequestVerificationUseCase>(requestUseCase)
        ..registerSingleton<GetResendInfoUseCase>(resendInfoUseCase)
        ..registerSingleton<ResendVerificationUseCase>(_MockResendUseCase())
        ..registerSingleton<VerifyContactUseCase>(_MockVerifyUseCase());
    });

    tearDown(sl.reset);

    /// Each settings surface binds the same sheet to its own purpose; the
    /// wire value must follow the surface, not a shared default.
    const cases = <String, (ContactField, VerificationPurpose, String, String)>{
      'Account Settings / owner email': (
        ContactField.email,
        VerificationPurpose.changeOwnerEmail,
        'new.owner@example.com',
        'new.owner@example.com',
      ),
      'Account Settings / owner phone': (
        ContactField.phone,
        VerificationPurpose.changeOwnerPhone,
        '509876543',
        '+971509876543',
      ),
      'General Settings / business email': (
        ContactField.email,
        VerificationPurpose.changeBusinessEmail,
        'new.biz@example.com',
        'new.biz@example.com',
      ),
      'General Settings / business phone': (
        ContactField.phone,
        VerificationPurpose.changeBusinessPhone,
        '509876543',
        '+971509876543',
      ),
    };

    for (final entry in cases.entries) {
      final name = entry.key;
      final (field, purpose, input, expectedTarget) = entry.value;

      testWidgets('$name sends /request with its own purpose', (tester) async {
        await _openSheet(tester, field: field, purpose: purpose);
        await _type(tester, input);
        await tester.ensureVisible(find.byType(AppButton));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(AppButton));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        final captured =
            verify(() => requestUseCase(captureAny())).captured.single
                as RequestVerificationParams;
        expect(captured.purpose, purpose);
        expect(captured.target, expectedTarget);

        // Bounded pumps only — the OTP field runs a repeating caret.
        await tester.pump(const Duration(milliseconds: 350));
      });
    }

    testWidgets(
      'resend-info is a probe, never a substitute for /request '
      '(regression: `canResend:false, remainingSeconds:0` means no session '
      'exists, and was being read as a live cooldown — so no code was sent)',
      (tester) async {
        await _openSheet(
          tester,
          field: ContactField.email,
          purpose: VerificationPurpose.changeOwnerEmail,
        );
        await _type(tester, 'new.owner@example.com');
        await tester.ensureVisible(find.byType(AppButton));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(AppButton));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        verify(() => requestUseCase(any())).called(1);
        await tester.pump(const Duration(milliseconds: 350));
      },
    );
  });
}

class _MockRequestUseCase extends Mock implements RequestVerificationUseCase {}

class _MockResendUseCase extends Mock implements ResendVerificationUseCase {}

class _MockVerifyUseCase extends Mock implements VerifyContactUseCase {}

class _MockResendInfoUseCase extends Mock implements GetResendInfoUseCase {}
