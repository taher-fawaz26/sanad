import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_app/src/core/gen/assets.gen.dart';
import 'package:sanad_app/src/core/themes/colors/app_colors.dart';
import 'package:sanad_app/src/core/themes/tokens.dart';
import 'package:sanad_app/src/core/ui/appbar/app_auth_app_bar.dart';
import 'package:sanad_app/src/core/ui/buttons/buttons.dart';
import 'package:sanad_app/src/core/ui/form_fields/app_otp_field.dart';
import 'package:sanad_app/src/core/ui/layout/app_layout.dart';
import 'package:sanad_app/src/core/ui/snackbar_widget.dart';
import 'package:sanad_app/src/core/ui/typography/app_text.dart';
import 'package:sanad_app/src/core/utils/constants/constants.dart';
import 'package:sanad_app/src/core/utils/create_new_password_args.dart';
import 'package:sanad_app/src/core/utils/otp_args.dart';
import 'package:sanad_app/src/core/utils/validators/validators.dart';
import 'package:sanad_app/src/features/auth/data/models/auth_otp_purpose.dart';
import 'package:sanad_app/src/features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'package:sanad_app/src/features/auth/presentation/cubit/otp_ui_cubit.dart';
import 'package:sanad_app/src/features/auth/presentation/cubit/otp_ui_state.dart';
import 'package:sanad_app/src/features/auth/presentation/widgets/auth_title_section.dart';

import '../../../../core/localization/localization_x.dart';
import '../../../../core/routes/app_route_path.dart';

/// Screen for displaying phone/email verification code input.
///
/// Receives [OtpArgs] as GoRouter `extra` — contains the [identifier]
/// (email/phone) and its [IdentifierType], so the page adapts its
/// title, icon, and subtitle without any detection logic.
class VerificationCodePage extends StatefulWidget {
  final OtpArgs args;

  const VerificationCodePage({super.key, required this.args});

  @override
  State<VerificationCodePage> createState() => _VerificationCodePageState();
}

class _VerificationCodePageState extends State<VerificationCodePage> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();

  @override
  void dispose() {
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  bool _validateOtp(BuildContext context) {
    final error = ValidationUtils.otp(
      Defaults.otpLength,
      emptyMessageKey: context.tr('validation.otp_required'),
      digitsOnlyMessageKey: context.tr('validation.otp_digits_only'),
      exactLengthMessageKey: context.tr(
        'validation.otp_exact_length',
        namedArgs: {'length': '${Defaults.otpLength}'},
      ),
    )(_otpController.text);
    context.read<OtpUiCubit>().setError(error);
    return error == null;
  }

  void _onOtpChanged(BuildContext context, String value) {
    final cubit = context.read<OtpUiCubit>();
    if (cubit.state.otpError != null) {
      _validateOtp(context);
    }
  }

  void _onVerifyAuth(BuildContext context) {
    if (!_validateOtp(context)) return;
    context.read<AuthBloc>().add(
      AuthValidateOtpEvent(
        widget.args.identifier,
        int.parse(_otpController.text),
      ),
    );
  }

  void _onVerifyForgot(BuildContext context) {
    if (!_validateOtp(context)) return;
    context.read<AuthBloc>().add(
      AuthVerifyForgotPasswordOtpEvent(
        widget.args.identifier,
        int.parse(_otpController.text),
      ),
    );
  }

  void _listenAuthState(BuildContext context, AuthState state) {
    if (state is AuthValidateOtpSuccessState) {
      AppSnackBar.show(
        context,
        message: context.trOrRaw(state.message),
        variant: SnackBarVariant.success,
      );
      context.goNamed(AppRoute.login.name);
    } else if (state is AuthValidateOtpFailureState) {
      AppSnackBar.show(
        context,
        message: context.trOrRaw(state.message),
        variant: SnackBarVariant.error,
      );
    } else if (state is AuthResendOtpSuccessState) {
      context.read<OtpUiCubit>().startTimer(AppDurations.otpCooldownSeconds);
      AppSnackBar.show(
        context,
        message: context.tr('auth_otp.otp_resent'),
        variant: SnackBarVariant.success,
      );
    } else if (state is AuthResendOtpFailureState) {
      AppSnackBar.show(
        context,
        message: context.trOrRaw(state.message),
        variant: SnackBarVariant.error,
      );
    }
  }

  void _listenForgotAuthState(BuildContext context, AuthState state) {
    if (state is AuthForgotPasswordOtpVerifiedState) {
      AppSnackBar.show(
        context,
        message: context.tr('auth_otp.otp_verified'),
        variant: SnackBarVariant.success,
      );
      context.pushNamed(
        AppRoute.createNewPassword.name,
        extra: CreateNewPasswordArgs(
          identifier: widget.args.identifier,
          type: widget.args.type,
        ),
      );
    } else if (state is AuthForgotPasswordOtpFailureState) {
      AppSnackBar.show(
        context,
        message: context.trOrRaw(state.message),
        variant: SnackBarVariant.error,
      );
    } else if (state is AuthForgotPasswordOtpReadyState) {
      context.read<OtpUiCubit>().startTimer(AppDurations.otpCooldownSeconds);
      AppSnackBar.show(
        context,
        message: context.tr('auth_otp.otp_resent'),
        variant: SnackBarVariant.success,
      );
    }
  }

  String _resendTimerLabel(int secondsRemaining) {
    final seconds = secondsRemaining.toString().padLeft(2, '0');
    return '00:$seconds';
  }

  Widget _otpColumn({
    required BuildContext context,
    required OtpUiState otpUi,
    required VoidCallback onVerify,
    required bool isVerifyButtonLoading,
    required VoidCallback? onResend,
    required bool isResendLoading,
  }) {
    final canResend = otpUi.secondsRemaining == 0;
    final otpError = otpUi.otpError;

    return AppLayout(
      appBar: const AppAuthAppBar(),
      sliverLayout: true,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.xxl,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: AppDimension.buttonLg,
            height: AppDimension.buttonLg,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.appColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: widget.args.type == IdentifierType.phone
                    ? Assets.svgs.user.svg()
                    : Assets.svgs.email.svg(),
              ),
            ),
          ),
          AuthTitleSection(
            title: widget.args.type == IdentifierType.phone
                ? context.tr('auth_otp.title_phone')
                : context.tr('auth_otp.title_email'),
            subtitle: context.tr(
              'auth_otp.subtitle',
              namedArgs: {
                'channel': context.tr(widget.args.channelLabelKey),
                'identifier': widget.args.identifier,
              },
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          AppOtpField(
            controller: _otpController,
            focusNode: _otpFocusNode,
            length: Defaults.otpLength,
            validator: ValidationUtils.otp(
              Defaults.otpLength,
              emptyMessageKey: context.tr('validation.otp_required'),
              digitsOnlyMessageKey: context.tr('validation.otp_digits_only'),
              exactLengthMessageKey: context.tr(
                'validation.otp_exact_length',
                namedArgs: {'length': '${Defaults.otpLength}'},
              ),
            ),
            forceErrorState: otpError != null,
            errorText: otpError,
            onChanged: (value) => _onOtpChanged(context, value),
            onCompleted: isVerifyButtonLoading ? null : (_) => onVerify(),
          ),
          AppButton.expand(
            label: context.tr('auth_otp.verify'),
            isLoading: isVerifyButtonLoading,
            onPressed: isVerifyButtonLoading ? null : onVerify,
          ),
          if (canResend && !isResendLoading)
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.xs,
              children: [
                AppText.bodyMedium(
                  context.tr('auth_otp.resend_prompt'),
                  textAlign: TextAlign.center,
                  tone: AppTextTone.secondary,
                ),
                GestureDetector(
                  onTap: onResend,
                  child: AppText.labelLarge(
                    context.tr('auth_otp.resend_action'),
                    tone: AppTextTone.brand,
                  ),
                ),
              ],
            )
          else
            AppText.bodyMedium(
              isResendLoading
                  ? context.tr('auth_otp.resend_prompt')
                  : '${context.tr('auth_otp.resend_prompt')} '
                        '${_resendTimerLabel(otpUi.secondsRemaining)}',
              textAlign: TextAlign.center,
              tone: AppTextTone.disabled,
            ),
          GestureDetector(
            onTap: () {
              context.goNamed(AppRoute.login.name);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.arrow_back,
                  color: context.appColors.textSecondary,
                  size: AppDimension.iconMd,
                ),
                SizedBox(width: AppSpacing.sm),
                AppText.labelLarge(
                  context.tr('auth_otp.back_to_login'),
                  tone: AppTextTone.secondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OtpUiCubit()..startTimer(AppDurations.otpCooldownSeconds),
      child: Builder(
        builder: (context) {
          if (widget.args.flow == OtpFlow.forgotPassword) {
            return BlocListener<AuthBloc, AuthState>(
              listenWhen: (previous, current) {
                if (current is AuthForgotPasswordOtpVerifiedState) {
                  return previous is AuthForgotPasswordOtpVerifyLoadingState;
                }
                if (current is AuthForgotPasswordOtpFailureState) {
                  return previous is AuthForgotPasswordOtpVerifyLoadingState ||
                      previous is AuthForgotPasswordOtpResendLoadingState;
                }
                if (current is AuthForgotPasswordOtpReadyState) {
                  return previous is AuthForgotPasswordOtpResendLoadingState;
                }
                return false;
              },
              listener: _listenForgotAuthState,
              child: BlocBuilder<AuthBloc, AuthState>(
                buildWhen: (previous, current) =>
                    current is AuthForgotPasswordOtpVerifyLoadingState ||
                    previous is AuthForgotPasswordOtpVerifyLoadingState ||
                    current is AuthForgotPasswordOtpResendLoadingState ||
                    previous is AuthForgotPasswordOtpResendLoadingState ||
                    current is AuthForgotPasswordOtpReadyState ||
                    current is AuthForgotPasswordOtpFailureState ||
                    current is AuthForgotPasswordOtpSentState,
                builder: (context, state) {
                  final verifyLoading =
                      state is AuthForgotPasswordOtpVerifyLoadingState;
                  final resendLoading =
                      state is AuthForgotPasswordOtpResendLoadingState;
                  return BlocBuilder<OtpUiCubit, OtpUiState>(
                    builder: (context, otpUi) {
                      return _otpColumn(
                        context: context,
                        otpUi: otpUi,
                        onVerify: () => _onVerifyForgot(context),
                        isVerifyButtonLoading: verifyLoading,
                        isResendLoading: resendLoading,
                        onResend: (verifyLoading || otpUi.secondsRemaining != 0)
                            ? null
                            : () => context.read<AuthBloc>().add(
                                AuthResendForgotPasswordOtpEvent(
                                  widget.args.identifier,
                                ),
                              ),
                      );
                    },
                  );
                },
              ),
            );
          }

          return BlocListener<AuthBloc, AuthState>(
            listener: _listenAuthState,
            child: BlocBuilder<AuthBloc, AuthState>(
              buildWhen: (previous, current) =>
                  current is AuthValidateOtpLoadingState ||
                  previous is AuthValidateOtpLoadingState ||
                  current is AuthResendOtpLoadingState ||
                  previous is AuthResendOtpLoadingState ||
                  current is AuthResendOtpSuccessState ||
                  current is AuthResendOtpFailureState,
              builder: (context, state) {
                final verifyLoading = state is AuthValidateOtpLoadingState;
                final resendLoading = state is AuthResendOtpLoadingState;
                return BlocBuilder<OtpUiCubit, OtpUiState>(
                  builder: (context, otpUi) {
                    return _otpColumn(
                      context: context,
                      otpUi: otpUi,
                      onVerify: () => _onVerifyAuth(context),
                      isVerifyButtonLoading: verifyLoading,
                      isResendLoading: resendLoading,
                      onResend: (verifyLoading || otpUi.secondsRemaining != 0)
                          ? null
                          : () => context.read<AuthBloc>().add(
                              AuthResendOtpEvent(
                                widget.args.identifier,
                                AuthOtpPurpose.register.wireValue,
                              ),
                            ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
