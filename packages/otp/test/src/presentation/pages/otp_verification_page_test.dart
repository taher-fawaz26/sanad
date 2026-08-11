import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:otp/otp.dart';

Future<void> _pumpApp(WidgetTester tester, Widget home) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      builder: (_, _) => MaterialApp(theme: AppTheme.light(), home: home),
    ),
  );
}

OtpFlowConfig<String> _configWith({
  required TaskEither<Failure, String> Function(String code) onVerifyCode,
  Duration resendCooldown = const Duration(seconds: 5),
}) {
  return OtpFlowConfig<String>.email(
    destination: 'user@example.com',
    resendCooldown: resendCooldown,
    verifier: CallbackOtpVerifier<String>(
      onRequestCode: () => TaskEither.right(const OtpDelivery()),
      onVerifyCode: onVerifyCode,
    ),
  );
}

void main() {
  group('OtpFlow.start', () {
    testWidgets('completes the full success flow and returns OtpVerified', (
      tester,
    ) async {
      OtpResult<String>? result;

      await _pumpApp(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await OtpFlow.start<String>(
                  context,
                  _configWith(
                    onVerifyCode: (code) => TaskEither.right('session-$code'),
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText).first, '123456');
      await tester.pumpAndSettle();

      // Auto-submits on completion; verifying, then success view.
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(result, isA<OtpVerified<String>>());
      expect((result! as OtpVerified<String>).data, 'session-123456');
    });

    testWidgets('resolves to OtpCancelled when dismissed via barrier tap', (
      tester,
    ) async {
      OtpResult<String>? result;

      await _pumpApp(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await OtpFlow.start<String>(
                  context,
                  _configWith(onVerifyCode: (_) => TaskEither.right('ok')),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(result, isA<OtpCancelled<String>>());
    });

    testWidgets('shows an inline error for an invalid code and stays open', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => OtpFlow.start<String>(
                context,
                _configWith(
                  onVerifyCode: (_) => TaskEither.left(
                    const ValidationFailure(message: 'wrong code'),
                  ),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText).first, '000000');
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text('otp.invalid_code'.tr()), findsOneWidget);
    });

    testWidgets('hides resend until the cooldown elapses, then enables it', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => OtpFlow.start<String>(
                context,
                _configWith(
                  onVerifyCode: (_) => TaskEither.right('ok'),
                  resendCooldown: const Duration(seconds: 2),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('otp.send_again'.tr()), findsNothing);

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(find.text('otp.send_again'.tr()), findsOneWidget);
    });
  });
}
