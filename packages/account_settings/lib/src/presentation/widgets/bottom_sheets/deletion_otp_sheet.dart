import 'package:account_settings/src/presentation/bloc/account_deletion/account_deletion_bloc.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/localization.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

/// Presents the deletion OTP step as a bottom-sheet modal (Figma "Confirm
/// Deletion" card). Shares the already-created [AccountDeletionBloc] via
/// [BlocProvider.value] so the server-driven resend cooldown and the active
/// request survive across the page → sheet boundary.
///
/// Resolves to `true` once the OTP is verified — by then the bloc has already
/// scheduled the deletion *and* ended the session (see
/// `AccountDeletionBloc._onOtpVerified`) — or `null` if the user dismisses
/// the sheet without verifying.
Future<bool?> showDeletionOtpSheet({
  required BuildContext context,
  required AccountDeletionBloc bloc,
}) {
  return SheetNavigator.push<bool>(
    context,
    BlocProvider<AccountDeletionBloc>.value(
      value: bloc,
      child: const _DeletionOtpSheetBody(),
    ),
    settings: const SheetRouteSettings(sheetSize: SheetSize.expanded),
  );
}

class _DeletionOtpSheetBody extends StatefulWidget {
  const _DeletionOtpSheetBody();

  @override
  State<_DeletionOtpSheetBody> createState() => _DeletionOtpSheetBodyState();
}

class _DeletionOtpSheetBodyState extends State<_DeletionOtpSheetBody> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<AccountDeletionBloc>().add(
      const AccountDeletionResendInfoRequested(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final otp = _controller.text.trim();
    if (otp.length < kDefaultOtpLength) {
      showAppErrorSnackbar(context: context, title: 'auth.otp_invalid'.tr());
      return;
    }
    context.read<AccountDeletionBloc>().add(AccountDeletionOtpVerified(otp));
  }

  void _resend() {
    _controller.clear();
    context.read<AccountDeletionBloc>().add(
      const AccountDeletionOtpResendRequested(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return MultiBlocListener(
      listeners: [
        // Verify: pop the sheet with `true` on success so the caller can route
        // to the scheduled screen; surface a snackbar on failure.
        BlocListener<AccountDeletionBloc, AccountDeletionState>(
          listenWhen: (p, c) => p.verifyStatus != c.verifyStatus,
          listener: (context, state) {
            if (state.verifyStatus == RequestStatus.success) {
              Navigator.of(context).pop(true);
            } else if (state.verifyStatus == RequestStatus.failure &&
                state.verifyFailure != null) {
              showAppErrorSnackbar(
                context: context,
                title: state.verifyFailure!.localizedMessage(),
              );
            }
          },
        ),
        // Resend: refresh the cooldown on success, surface errors on failure.
        BlocListener<AccountDeletionBloc, AccountDeletionState>(
          listenWhen: (p, c) => p.resendStatus != c.resendStatus,
          listener: (context, state) {
            if (state.resendStatus == RequestStatus.success) {
              showAppSnackbar(
                context: context,
                title: 'auth.otp_resent'.tr(),
                color: AppSnackbarColor.primary,
              );
              context.read<AccountDeletionBloc>().add(
                const AccountDeletionResendInfoRequested(),
              );
            } else if (state.resendStatus == RequestStatus.failure &&
                state.mutationFailure != null) {
              showAppErrorSnackbar(
                context: context,
                title: state.mutationFailure!.localizedMessage(),
              );
            }
          },
        ),
      ],
      child: BlocBuilder<AccountDeletionBloc, AccountDeletionState>(
        builder: (context, state) {
          final resendInfo = state.resendInfo;
          // Show the countdown only while the server-driven cooldown is
          // actually ticking. Once it hits zero (or is unknown) the resend
          // link is actionable — never render "Resend in 0 seconds". If resend
          // is truly exhausted the backend answers 429 and we surface that
          // error, rather than pre-emptively disabling the only way forward.
          final remaining = resendInfo?.remainingSeconds ?? 0;
          final counting = remaining > 0;
          final isVerifying = state.verifyStatus == RequestStatus.loading;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: colors.errorContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.mail_outline_rounded,
                    color: colors.error,
                    size: 28,
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              Text(
                'account_deletion.otp_sheet_title'.tr(),
                style: typography.title3.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                'account_deletion.otp_sheet_subtitle'.tr(),
                style: typography.regularNormal.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              SizedBox(height: AppSpacing.xxl),
              Center(
                child: AppOtpField(
                  controller: _controller,
                  autofocus: true,
                  enabled: !isVerifying,
                  onSubmitted: (_) => _submit(),
                ),
              ),
              SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'account_deletion.otp_confirm_button'.tr(),
                destructive: true,
                isLoading: isVerifying,
                onPressed: isVerifying ? null : _submit,
              ),
              SizedBox(height: AppSpacing.lg),
              Center(
                child: Text.rich(
                  TextSpan(
                    style: typography.regularNormal.copyWith(
                      color: colors.textSecondary,
                    ),
                    children: [
                      TextSpan(text: 'auth.otp_not_received'.tr()),
                      TextSpan(
                        text: counting
                            ? 'account_deletion.otp_resend_cooldown'.tr(
                                namedArgs: {'seconds': '$remaining'},
                              )
                            : 'common.resend'.tr(),
                        style: TextStyle(
                          color: counting ? colors.textMuted : colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        recognizer: counting
                            ? null
                            : (TapGestureRecognizer()..onTap = _resend),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
