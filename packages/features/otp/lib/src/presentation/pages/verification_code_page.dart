import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
import 'package:otp/src/presentation/bloc/otp_ui_cubit.dart';
import 'package:otp/src/domain/enums/otp_purpose.dart';
import 'package:otp/src/presentation/models/otp_args.dart';
import 'package:otp/src/presentation/bloc/otp_bloc.dart';
import 'package:otp/src/presentation/widgets/app_otp_field.dart';

/// Register-flow OTP verification screen.
class VerificationCodePage extends HookWidget {
  const VerificationCodePage({
    required this.args,
    super.key,
    this.onVerified,
    this.onBackToLogin,
  });

  final OtpArgs args;
  final VoidCallback? onVerified;
  final VoidCallback? onBackToLogin;

  @override
  Widget build(BuildContext context) {
    final otpController = useTextEditingController();
    final formKey = useMemoized(GlobalKey<FormState>.new);

    return BlocProvider(
      create: (_) => OtpUiCubit()..startTimer(),
      child: BlocListener<OtpBloc, OtpState>(
        listener: (context, state) {
          if (state is OtpValidateSuccessState) {
            showAppSnackbar(
              context: context,
              title: state.message.tr(),
              color: AppSnackbarColor.primary,
            );
            onVerified?.call();
          } else if (state is OtpValidateFailureState) {
            showAppErrorSnackbar(
              context: context,
              title: state.failure.localizedMessage(),
            );
          } else if (state is OtpResendSuccessState) {
            context.read<OtpUiCubit>().startTimer();
            showAppSnackbar(
              context: context,
              title: 'otp.resent'.tr(),
              color: AppSnackbarColor.primary,
            );
          } else if (state is OtpResendFailureState) {
            showAppErrorSnackbar(
              context: context,
              title: state.failure.localizedMessage(),
            );
          }
        },
        child: Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                const AppHeader(),
                const AppDivider(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacingDp.xxl),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: AppSpacingDp.xxxl),
                          Center(
                            child: AppAvatar(
                              initials: args.type == IdentifierType.phone
                                  ? 'P'
                                  : 'E',
                            ),
                          ),
                          const SizedBox(height: AppSpacingDp.xxl),
                          AppSection(
                            title: args.type == IdentifierType.phone
                                ? 'otp.title_phone'.tr()
                                : 'otp.title_email'.tr(),
                            caption: 'otp.subtitle'.tr(
                              namedArgs: {
                                'channel': args.channelLabelKey.tr(),
                                'identifier': args.identifier,
                              },
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          const SizedBox(height: AppSpacingDp.xxl),
                          BlocBuilder<OtpUiCubit, OtpUiState>(
                            buildWhen: (previous, current) =>
                                previous.otpError != current.otpError,
                            builder: (context, otpUi) {
                              return AppOtpField(
                                controller: otpController,
                                autofocus: true,
                                forceErrorState: otpUi.otpError != null,
                                errorText: otpUi.otpError,
                                validator: (value) {
                                  final text = value?.trim() ?? '';
                                  if (text.isEmpty) {
                                    return 'otp.required'.tr();
                                  }
                                  if (text.length != kDefaultOtpLength) {
                                    return 'otp.exact_length'.tr(
                                      namedArgs: {
                                        'length': '$kDefaultOtpLength',
                                      },
                                    );
                                  }
                                  return null;
                                },
                                onChanged: (_) {
                                  if (otpUi.otpError != null) {
                                    context.read<OtpUiCubit>().setError(null);
                                  }
                                },
                                onCompleted: (_) => _verify(
                                  context,
                                  formKey,
                                  otpController,
                                ),
                                onSubmitted: (_) => _verify(
                                  context,
                                  formKey,
                                  otpController,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: AppSpacingDp.xxl),
                          BlocBuilder<OtpBloc, OtpState>(
                            builder: (context, state) {
                              final isLoading =
                                  state is OtpValidateLoadingState;
                              return AppButton(
                                label: 'otp.verify'.tr(),
                                isLoading: isLoading,
                                onPressed: isLoading
                                    ? null
                                    : () => _verify(
                                          context,
                                          formKey,
                                          otpController,
                                        ),
                              );
                            },
                          ),
                          const SizedBox(height: AppSpacingDp.lg),
                          BlocBuilder<OtpBloc, OtpState>(
                            builder: (context, otpState) {
                              return BlocBuilder<OtpUiCubit, OtpUiState>(
                                buildWhen: (previous, current) =>
                                    previous.secondsRemaining !=
                                    current.secondsRemaining,
                                builder: (context, otpUi) {
                                  final resendLoading =
                                      otpState is OtpResendLoadingState;
                                  final canResend =
                                      otpUi.secondsRemaining == 0 &&
                                          !resendLoading;

                                  if (canResend) {
                                    return AppButton(
                                      label: 'otp.resend'.tr(),
                                      type: AppButtonType.transparent,
                                      onPressed: () {
                                        context.read<OtpBloc>().add(
                                              OtpResendEvent(
                                                identifier: args.identifier,
                                                purpose:
                                                    args.flow ==
                                                        OtpFlow.forgotPassword
                                                    ? OtpPurpose.forgotPassword
                                                    : OtpPurpose.register,
                                              ),
                                            );
                                      },
                                    );
                                  }

                                  final label = resendLoading
                                      ? 'otp.resend'.tr()
                                      : '${'otp.resend_in'.tr()} '
                                          '00:${otpUi.secondsRemaining.toString().padLeft(2, '0')}';
                                  return Text(
                                    label,
                                    textAlign: TextAlign.center,
                                    style: context.appTypography.regularNormal
                                        .copyWith(
                                      color: context.appColors.textMuted,
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          const SizedBox(height: AppSpacingDp.lg),
                          AppButton(
                            label: 'otp.back_to_login'.tr(),
                            type: AppButtonType.transparent,
                            icon: Icon(
                              Icons.arrow_back,
                              color: context.appColors.textSecondary,
                            ),
                            iconPosition: AppButtonIconPosition.left,
                            onPressed: () {
                              if (onBackToLogin != null) {
                                onBackToLogin!();
                              } else {
                                context.go(AuthRoutes.login);
                              }
                            },
                          ),
                          const SizedBox(height: AppSpacingDp.xxxl),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _verify(
    BuildContext context,
    GlobalKey<FormState> formKey,
    TextEditingController otpController,
  ) {
    final cubit = context.read<OtpUiCubit>();
    if (!(formKey.currentState?.validate() ?? false)) {
      cubit.setError('otp.required'.tr());
      return;
    }
    cubit.setError(null);
    context.read<OtpBloc>().add(
          OtpValidateEvent(
            identifier: args.identifier,
            otp: int.parse(otpController.text.trim()),
          ),
        );
  }
}
