import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:otp/otp.dart';

/// easy_localization is not initialised in these tests, so `.tr()` returns the
/// key itself. Assertions therefore target keys, not copy — they verify
/// wiring, not translations.
Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 800),
      builder: (_, _) => MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pump();
}

OtpFlowConfig<String> _config({
  TaskEither<Failure, OtpDelivery> Function()? onRequest,
  TaskEither<Failure, OtpCooldown> Function()? onCooldown,
  TaskEither<Failure, String> Function(String code)? onVerify,
  bool autoSubmit = true,
  bool showSuccessScreen = false,
}) => OtpFlowConfig<String>.email(
  destination: 'user@example.com',
  autoSubmit: autoSubmit,
  showSuccessScreen: showSuccessScreen,
  verifier: CallbackOtpVerifier<String>(
    onRequestCode: onRequest ?? () => TaskEither.right(const OtpDelivery()),
    onCooldown:
        onCooldown ??
        () => TaskEither.right(
          const OtpCooldown(canResend: true, remainingSeconds: 0),
        ),
    onVerifyCode: onVerify ?? (_) => TaskEither.right('session-123456'),
  ),
);

Future<void> _enterCode(WidgetTester tester, String code) async {
  await tester.enterText(find.byType(EditableText).first, code);
  await tester.pump();
}

void main() {
  group('OtpHost', () {
    testWidgets('verifies a code and reports the payload', (tester) async {
      OtpResult<String>? result;
      await _pump(
        tester,
        OtpHost<String>(
          config: _config(),
          onResult: (r) => result = r,
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      await _enterCode(tester, '123456');
      await tester.pump(const Duration(milliseconds: 50));

      expect(result, isA<OtpVerified<String>>());
      expect((result! as OtpVerified<String>).data, 'session-123456');
    });

    testWidgets('shows an inline error for an invalid code and stays open', (
      tester,
    ) async {
      OtpResult<String>? result;
      await _pump(
        tester,
        OtpHost<String>(
          config: _config(
            onVerify: (_) =>
                TaskEither.left(const ValidationFailure(message: 'nope')),
          ),
          onResult: (r) => result = r,
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      await _enterCode(tester, '123456');
      await tester.pump(const Duration(milliseconds: 50));

      expect(result, isNull);
      expect(find.text('otp.invalid_code'.tr()), findsOneWidget);
    });

    testWidgets(
      'a live server cooldown renders a countdown and NO error '
      '(regression: reopening inside a cooldown showed an error under an '
      'empty field)',
      (tester) async {
        var requested = false;
        await _pump(
          tester,
          OtpHost<String>(
            config: _config(
              onRequest: () {
                requested = true;
                return TaskEither.right(const OtpDelivery());
              },
              onCooldown: () => TaskEither.right(
                const OtpCooldown(canResend: false, remainingSeconds: 90),
              ),
            ),
            onResult: (_) {},
          ),
        );
        await tester.pump(const Duration(milliseconds: 50));

        expect(requested, isFalse, reason: 'no send, so no 429 to surface');
        expect(find.text('01:30'), findsOneWidget);
        expect(find.text('otp.invalid_code'.tr()), findsNothing);
        expect(find.text('otp.expired_code'.tr()), findsNothing);
      },
    );

    testWidgets('a delivery failure renders in the banner with a retry', (
      tester,
    ) async {
      await _pump(
        tester,
        OtpHost<String>(
          config: _config(
            onRequest: () =>
                TaskEither.left(const ConflictFailure(message: 'Taken')),
          ),
          onResult: (_) {},
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Taken'), findsOneWidget);
      expect(find.text('otp.retry'.tr()), findsOneWidget);
      // A delivery problem is never a field error.
      expect(find.text('otp.invalid_code'.tr()), findsNothing);
    });

    testWidgets('the resend link is disabled while the countdown runs', (
      tester,
    ) async {
      await _pump(
        tester,
        OtpHost<String>(
          config: _config(
            onCooldown: () => TaskEither.right(
              const OtpCooldown(canResend: false, remainingSeconds: 30),
            ),
          ),
          onResult: (_) {},
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      // Always present so the layout does not jump, but not actionable yet.
      // It is a TextSpan inside the resend row, hence findRichText.
      expect(
        find.textContaining('otp.send_again'.tr(), findRichText: true),
        findsOneWidget,
      );
      expect(find.text('00:30'), findsOneWidget);
    });

    testWidgets('a 409 on verify closes the flow with OtpFailed', (
      tester,
    ) async {
      OtpResult<String>? result;
      await _pump(
        tester,
        OtpHost<String>(
          config: _config(
            onVerify: (_) =>
                TaskEither.left(const ConflictFailure(message: 'Claimed')),
          ),
          onResult: (r) => result = r,
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      await _enterCode(tester, '123456');
      await tester.pump(const Duration(milliseconds: 50));

      expect(result, isA<OtpFailed<String>>());
    });
  });
}
