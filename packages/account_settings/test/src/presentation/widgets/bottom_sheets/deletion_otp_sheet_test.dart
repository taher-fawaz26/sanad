// Deletion OTP "Confirm Deletion" sheet: the resend row shows a countdown
// only while the server cooldown is actually ticking (never "Resend in 0
// seconds"), and there is no yellow "last attempt" warning. EasyLocalization
// is not bootstrapped, so `.tr()` falls back to raw keys.
//
// The OTP field runs a repeating caret animation, so these tests use bounded
// `pump()`s — never `pumpAndSettle()`.
import 'package:account_settings/src/domain/entities/deletion_resend_info.dart';
import 'package:account_settings/src/presentation/bloc/account_deletion/account_deletion_bloc.dart';
import 'package:account_settings/src/presentation/widgets/bottom_sheets/deletion_otp_sheet.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAccountDeletionBloc
    extends MockBloc<AccountDeletionEvent, AccountDeletionState>
    implements AccountDeletionBloc {}

Future<void> _openSheet(
  WidgetTester tester,
  AccountDeletionBloc bloc,
) async {
  tester.view.physicalSize = const Size(400, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(400, 800),
      builder: (_, _) => MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () =>
                  showDeletionOtpSheet(context: context, bloc: bloc),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  // Bounded pumps to let the modal-sheet route animate in (no pumpAndSettle —
  // the OTP caret animation never settles).
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  setUpAll(() {
    registerFallbackValue(const AccountDeletionResendInfoRequested());
    registerFallbackValue(const AccountDeletionOtpResendRequested());
  });

  late _MockAccountDeletionBloc bloc;

  void seed(DeletionResendInfo info) {
    bloc = _MockAccountDeletionBloc();
    whenListen(
      bloc,
      const Stream<AccountDeletionState>.empty(),
      initialState: AccountDeletionState(resendInfo: info),
    );
  }

  testWidgets(
    'remainingSeconds == 0 shows an actionable Resend Code, never "0 seconds"',
    (tester) async {
      // canResend=false + remaining=0 is the exact stale state that used to
      // render "Resend in 0 seconds".
      seed(
        const DeletionResendInfo(
          canResend: false,
          remainingSeconds: 0,
          attemptsLeft: 3,
        ),
      );
      await _openSheet(tester, bloc);

      expect(find.textContaining('common.resend'), findsOneWidget);
      expect(
        find.textContaining('account_deletion.otp_resend_cooldown'),
        findsNothing,
      );
    },
  );

  testWidgets('remainingSeconds > 0 shows the cooldown, not the resend link', (
    tester,
  ) async {
    seed(
      const DeletionResendInfo(
        canResend: false,
        remainingSeconds: 30,
        attemptsLeft: 3,
      ),
    );
    await _openSheet(tester, bloc);

    expect(
      find.textContaining('account_deletion.otp_resend_cooldown'),
      findsOneWidget,
    );
    expect(find.textContaining('common.resend'), findsNothing);
  });

  testWidgets(
    'no yellow "last attempt" warning even when attemptsLeft is low',
    (
      tester,
    ) async {
      seed(
        const DeletionResendInfo(
          canResend: true,
          remainingSeconds: 0,
          attemptsLeft: 1,
        ),
      );
      await _openSheet(tester, bloc);

      expect(
        find.textContaining('account_deletion.otp_last_attempt'),
        findsNothing,
      );
      expect(find.byType(AppAlert), findsNothing);
    },
  );
}
