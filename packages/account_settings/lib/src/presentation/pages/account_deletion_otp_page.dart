import 'package:account_settings/src/presentation/bloc/account_deletion/account_deletion_bloc.dart';
import 'package:account_settings/src/routes/account_settings_routes.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
import 'package:shared_ui/shared_ui.dart';

/// OTP verification for a pending account-deletion request. Reuses the
/// shared [AppOtpField] and the server-driven resend cooldown
/// (`canResend`/`remainingSeconds`/`attemptsLeft`) — no client-invented
/// timer.
class AccountDeletionOtpPage extends StatefulWidget {
  const AccountDeletionOtpPage({super.key});

  @override
  State<AccountDeletionOtpPage> createState() => _AccountDeletionOtpPageState();
}

class _AccountDeletionOtpPageState extends State<AccountDeletionOtpPage> {
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
    return BlocConsumer<AccountDeletionBloc, AccountDeletionState>(
      listenWhen: (previous, current) =>
          previous.resendStatus != current.resendStatus,
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
      builder: (context, state) {
        final resendInfo = state.resendInfo;
        final canResend = resendInfo?.canResend ?? false;
        final remainingSeconds = '${resendInfo?.remainingSeconds ?? 0}';
        final isVerifying = state.mutationStatus == RequestStatus.loading;
        final colors = context.appColors;
        final typography = context.appTypography;

        return MutationListener<AccountDeletionBloc, AccountDeletionState>(
          status: (s) => s.mutationStatus,
          title: (context) => 'account_deletion.verifying_title'.tr(),
          listenWhen: (previous, current) =>
              previous.mutationStatus != current.mutationStatus,
          onFailure: (context, s) {
            if (s.mutationFailure != null) {
              showAppErrorSnackbar(
                context: context,
                title: s.mutationFailure!.localizedMessage(),
              );
            }
          },
          onSuccess: (context, s) =>
              context.pushReplacement(AccountSettingsRoutes.deletionScheduled),
          child: AppScrollPage(
            slivers: [
              AppSliverAppBar(
                navBar: AppNavBar(
                  title: 'account_deletion.otp_title'.tr(),
                  showBackButton: true,
                  onLeadingTap: () => context.pop(),
                ),
              ),
              AppSliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.lg,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'account_deletion.otp_subtitle'.tr(),
                        style: typography.regularNormal.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xxxl),
                      Center(
                        child: AppOtpField(
                          controller: _controller,
                          autofocus: true,
                          enabled: !isVerifying,
                          onSubmitted: (_) => _submit(),
                        ),
                      ),
                      SizedBox(height: AppSpacing.xl),
                      if (resendInfo != null && resendInfo.attemptsLeft <= 1)
                        Padding(
                          padding: EdgeInsets.only(bottom: AppSpacing.lg),
                          child: AppAlert(
                            message: 'account_deletion.otp_last_attempt'.tr(),
                            type: AppAlertType.warning,
                          ),
                        ),
                      AppButton(
                        label: 'auth.verify'.tr(),
                        isLoading: isVerifying,
                        onPressed: isVerifying ? null : _submit,
                      ),
                      SizedBox(height: AppSpacing.xl),
                      Center(
                        child: Text.rich(
                          TextSpan(
                            style: typography.regularNormal.copyWith(
                              color: colors.textSecondary,
                            ),
                            children: [
                              TextSpan(text: 'auth.otp_not_received'.tr()),
                              TextSpan(
                                text: canResend
                                    ? 'common.resend'.tr()
                                    : 'account_deletion.otp_resend_cooldown'.tr(
                                        namedArgs: {
                                          'seconds': remainingSeconds,
                                        },
                                      ),
                                style: TextStyle(
                                  color: canResend
                                      ? colors.primary
                                      : colors.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                                recognizer: canResend
                                    ? (TapGestureRecognizer()..onTap = _resend)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
