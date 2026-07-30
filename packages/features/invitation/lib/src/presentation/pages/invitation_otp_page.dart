import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:invitation/src/domain/entities/invitation_mock.dart';
import 'package:invitation/src/presentation/widgets/invitation_screen_shell.dart';
import 'package:invitation/src/routes/invitation_routes.dart';

/// Mocked resend cooldown matching the Figma countdown (`01:30`).
const _resendCooldown = Duration(seconds: 90);

/// Screen 2 — OTP entry (Figma `2560:24688`).
///
/// UI-only: "Verify" does not call any API — it simply advances to the
/// mocked success screen. Countdown/resend are local, fake state.
class InvitationOtpPage extends StatefulWidget {
  const InvitationOtpPage({
    this.invitation = InvitationMock.sample,
    super.key,
  });

  final InvitationMock invitation;

  @override
  State<InvitationOtpPage> createState() => _InvitationOtpPageState();
}

class _InvitationOtpPageState extends State<InvitationOtpPage> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  bool _verifying = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify(OtpUiCubit cubit) async {
    if (_verifying) return;
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      cubit.setError('invitation.otp_required'.tr());
      return;
    }
    cubit.setError(null);

    setState(() => _verifying = true);
    // Mocked verification delay — no backend call.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _verifying = false);

    await context.push(InvitationRoutes.success, extra: widget.invitation);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return BlocProvider(
      create: (_) => OtpUiCubit()..startTimer(_resendCooldown),
      child: InvitationScreenShell(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text(
                  'invitation.otp_title'.tr(),
                  style: typography.title1.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                    height: 40 / 32,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'invitation.otp_subtitle'.tr(
                    namedArgs: {'email': widget.invitation.email},
                  ),
                  style: typography.regularNormal.copyWith(
                    color: colors.textSecondary,
                    height: 24 / 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.xxl),
                BlocBuilder<OtpUiCubit, OtpUiState>(
                  buildWhen: (previous, current) =>
                      previous.otpError != current.otpError,
                  builder: (context, otpUi) {
                    return AppOtpField(
                      controller: _otpController,
                      autofocus: true,
                      forceErrorState: otpUi.otpError != null,
                      errorText: otpUi.otpError,
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.length != kDefaultOtpLength) {
                          return 'invitation.otp_required'.tr();
                        }
                        return null;
                      },
                      onChanged: (_) {
                        if (otpUi.otpError != null) {
                          context.read<OtpUiCubit>().setError(null);
                        }
                      },
                      onCompleted: (_) =>
                          _verify(context.read<OtpUiCubit>()),
                    );
                  },
                ),
                SizedBox(height: AppSpacing.xxl),
                AppButton(
                  label: 'invitation.verify_button'.tr(),
                  isLoading: _verifying,
                  onPressed: _verifying
                      ? null
                      : () => _verify(context.read<OtpUiCubit>()),
                ),
                SizedBox(height: AppSpacing.lg),
                BlocBuilder<OtpUiCubit, OtpUiState>(
                  buildWhen: (previous, current) =>
                      previous.secondsRemaining != current.secondsRemaining,
                  builder: (context, otpUi) {
                    final canResend = otpUi.secondsRemaining == 0;
                    final minutes = otpUi.secondsRemaining ~/ 60;
                    final seconds = otpUi.secondsRemaining % 60;
                    final timerLabel =
                        '${minutes.toString().padLeft(2, '0')}:'
                        '${seconds.toString().padLeft(2, '0')}';

                    return Column(
                      children: [
                        if (!canResend)
                          Text(
                            timerLabel,
                            style: typography.regularNormal.copyWith(
                              color: colors.primary,
                            ),
                          ),
                        SizedBox(height: AppSpacing.md),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'invitation.otp_no_code'.tr(),
                              style: typography.regularNormal.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: canResend
                                  ? () {
                                      context.read<OtpUiCubit>().startTimer(
                                        _resendCooldown,
                                      );
                                      showAppSnackbar(
                                        context: context,
                                        title: 'invitation.otp_resent'.tr(),
                                      );
                                    }
                                  : null,
                              child: Text(
                                'invitation.otp_send_again'.tr(),
                                style: typography.regularNormal.copyWith(
                                  color: canResend
                                      ? colors.primary
                                      : colors.textMuted,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
