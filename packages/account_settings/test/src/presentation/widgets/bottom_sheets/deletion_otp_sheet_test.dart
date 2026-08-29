import 'package:account_settings/src/domain/entities/account_deletion_request.dart';
import 'package:account_settings/src/domain/enums/account_deletion_status.dart';
import 'package:account_settings/src/domain/entities/deletion_resend_info.dart';
import 'package:account_settings/src/presentation/widgets/bottom_sheets/deletion_otp_sheet.dart';
import 'package:account_settings/src/domain/usecases/account_settings_params.dart';
import 'package:account_settings/src/domain/usecases/get_deletion_resend_info_usecase.dart';
import 'package:account_settings/src/domain/usecases/resend_deletion_otp_usecase.dart';
import 'package:account_settings/src/domain/usecases/verify_deletion_otp_usecase.dart';
import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockVerifyOtp extends Mock implements VerifyDeletionOtpUseCase {}

class _MockResendOtp extends Mock implements ResendDeletionOtpUseCase {}

class _MockResendInfo extends Mock implements GetDeletionResendInfoUseCase {}

class _MockLogout extends Mock implements AuthLogoutUseCase {}

class _MockSessionManager extends Mock implements SessionManager {}

final _request = AccountDeletionRequest(
  id: 'req-1',
  status: AccountDeletionStatus.scheduled,
  initiator: DeletionInitiator.self,
  verificationRequired: false,
  scheduledExecutionDate: DateTime(2026, 9, 2),
  gracePeriodDays: 14,
  message: 'scheduled',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  late _MockVerifyOtp verifyOtp;
  late _MockResendOtp resendOtp;
  late _MockResendInfo resendInfo;
  late _MockLogout logout;
  late _MockSessionManager sessionManager;

  setUpAll(() {
    registerFallbackValue(const VerifyDeletionOtpParams(otp: '000000'));
    registerFallbackValue(const NoParams());
  });

  setUp(() {
    verifyOtp = _MockVerifyOtp();
    resendOtp = _MockResendOtp();
    resendInfo = _MockResendInfo();
    logout = _MockLogout();
    sessionManager = _MockSessionManager();

    when(() => resendInfo(any())).thenAnswer(
      (_) => TaskEither.right(
        const DeletionResendInfo(
          canResend: false,
          remainingSeconds: 30,
          attemptsLeft: 4,
        ),
      ),
    );
    when(() => logout(any())).thenAnswer((_) => TaskEither.right(null));
    when(sessionManager.clear).thenAnswer((_) async {});

    sl
      ..registerFactory<VerifyDeletionOtpUseCase>(() => verifyOtp)
      ..registerFactory<ResendDeletionOtpUseCase>(() => resendOtp)
      ..registerFactory<GetDeletionResendInfoUseCase>(() => resendInfo)
      ..registerFactory<AuthLogoutUseCase>(() => logout)
      ..registerFactory<SessionManager>(() => sessionManager);
  });

  tearDown(sl.reset);

  Future<bool?> openSheet(WidgetTester tester) async {
    bool? outcome;
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 800),
        builder: (_, _) => MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async =>
                    outcome = await showDeletionOtpSheet(context: context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    return outcome;
  }

  testWidgets(
    'opening the sheet does not mint a second code - one was already sent '
    'with POST /account/deletion',
    (tester) async {
      await openSheet(tester);
      await tester.pump(const Duration(milliseconds: 50));

      verifyNever(() => resendOtp(any()));
      verify(() => resendInfo(any())).called(greaterThanOrEqualTo(1));
    },
  );

  testWidgets('a verified code ends the session before the sheet resolves', (
    tester,
  ) async {
    when(() => verifyOtp(any())).thenAnswer((_) => TaskEither.right(_request));

    await openSheet(tester);
    await tester.pump(const Duration(milliseconds: 50));

    await tester.enterText(find.byType(EditableText).first, '123456');
    await tester.pump();
    // Submit via the keyboard action rather than the button: inside the sheet
    // viewport the button can sit below the fold, and this exercises the same
    // OtpSubmitted path.
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump(const Duration(milliseconds: 150));

    // The session teardown is inseparable from verification - a user must
    // never be left signed into an account scheduled for deletion.
    verify(() => logout(any())).called(1);
    verify(sessionManager.clear).called(1);
  });

  testWidgets('a rejected code keeps the sheet open with a field error', (
    tester,
  ) async {
    when(() => verifyOtp(any())).thenAnswer(
      (_) => TaskEither.left(const ValidationFailure(message: 'bad code')),
    );

    await openSheet(tester);
    await tester.pump(const Duration(milliseconds: 50));

    await tester.enterText(find.byType(EditableText).first, '123456');
    await tester.pump();
    // Submit via the keyboard action rather than the button: inside the sheet
    // viewport the button can sit below the fold, and this exercises the same
    // OtpSubmitted path.
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump(const Duration(milliseconds: 150));

    verifyNever(() => logout(any()));
    expect(find.byType(AppOtpField), findsOneWidget);
  });
}
