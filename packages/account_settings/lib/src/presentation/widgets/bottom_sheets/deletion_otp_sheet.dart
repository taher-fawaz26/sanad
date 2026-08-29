import 'package:account_settings/src/domain/entities/account_deletion_request.dart';
import 'package:account_settings/src/domain/usecases/get_deletion_resend_info_usecase.dart';
import 'package:account_settings/src/domain/usecases/resend_deletion_otp_usecase.dart';
import 'package:account_settings/src/domain/usecases/verify_deletion_otp_usecase.dart';
import 'package:account_settings/src/domain/verifiers/deletion_otp_verifier.dart';
import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:otp/otp.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

/// Presents the deletion OTP step as a bottom-sheet modal (Figma "Confirm
/// Deletion" card), using the app's canonical OTP screen.
///
/// Resolves to `true` once the OTP is verified — by then the deletion is
/// scheduled *and* the session has ended (see [DeletionOtpVerifier]) — or
/// `null` if the user dismisses the sheet without verifying.
Future<bool?> showDeletionOtpSheet({required BuildContext context}) async {
  final result = await SheetNavigator.push<OtpResult<AccountDeletionRequest>>(
    context,
    const _DeletionOtpSheet(),
    settings: const SheetRouteSettings(sheetSize: SheetSize.expanded),
  );
  return (result?.isVerified ?? false) ? true : null;
}

class _DeletionOtpSheet extends StatelessWidget {
  const _DeletionOtpSheet();

  @override
  Widget build(BuildContext context) {
    return OtpHost<AccountDeletionRequest>(
      config: OtpFlowConfig<AccountDeletionRequest>.email(
        destination: '',
        purpose: OtpPurpose.deleteAccount,
        // The code went out with `POST /account/deletion`; opening this sheet
        // must not mint a second one.
        autoSendOnStart: false,
        // A wrong code here is expensive, and the action is destructive:
        // require an explicit tap rather than firing on the last digit.
        autoSubmit: false,
        // The user is being signed out — a "verified!" screen would flash in
        // front of the logout they just triggered.
        showSuccessScreen: false,
        titleBuilder: (_, _) => 'account_deletion.otp_sheet_title'.tr(),
        subtitleBuilder: (_, _) => 'account_deletion.otp_sheet_subtitle'.tr(),
        verifier: DeletionOtpVerifier(
          verifyOtp: sl<VerifyDeletionOtpUseCase>(),
          resendOtp: sl<ResendDeletionOtpUseCase>(),
          getResendInfo: sl<GetDeletionResendInfoUseCase>(),
          logout: sl<AuthLogoutUseCase>(),
          sessionManager: sl<SessionManager>(),
        ),
      ),
      onResult: (result) {
        if (!context.mounted) return;
        Navigator.of(context).pop(result);
      },
    );
  }
}
