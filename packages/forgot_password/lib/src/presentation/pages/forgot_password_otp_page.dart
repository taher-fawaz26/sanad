import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forgot_password/src/models/create_new_password_args.dart';
import 'package:forgot_password/src/presentation/bloc/forgot_password_bloc.dart';
import 'package:forgot_password/src/routes/forgot_password_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:otp/otp.dart';

/// Forgot-password OTP verification screen.
class ForgotPasswordOtpPage extends HookWidget {
  const ForgotPasswordOtpPage({
    required this.args,
    super.key,
    this.onVerified,
    this.onBackToLogin,
  });

  final OtpArgs args;
  final ValueChanged<String>? onVerified;
  final VoidCallback? onBackToLogin;

  @override
  Widget build(BuildContext context) {
    final otpController = useTextEditingController();
    final formKey = useMemoized(GlobalKey<FormState>.new);

    return BlocProvider(
      create: (_) => OtpUiCubit()..startTimer(),
      child: BlocListener<ForgotPasswordBloc, ForgotPasswordState>(
        listener: (context, state) {
          if (state is ForgotPasswordOtpVerifiedState) {
            showAppSnackbar(
              context: context,
              title: 'forgot_password.otp_verified'.tr(),
              color: AppSnackbarColor.primary,
            );
            if (onVerified != null) {
              onVerified!(args.identifier);
            } else {
              context.push(
                ForgotPasswordRoutes.resetPassword,
                extra: CreateNewPasswordArgs(identifier: args.identifier),
              );
            }
          } else if (state is ForgotPasswordOtpFailureState) {
            showAppSnackbar(context: context, title: state.message.tr());
          } else if (state is ForgotPasswordOtpReadyState) {
            context.read<OtpUiCubit>().startTimer();
            showAppSnackbar(
              context: context,
              title: 'forgot_password.otp_resent'.tr(),
              color: AppSnackbarColor.primary,
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
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 32),
                          const Center(child: AppAvatar(initials: 'E')),
                          const SizedBox(height: 24),
                          AppSection(
                            title: 'forgot_password.otp_title'.tr(),
                            caption: 'forgot_password.otp_subtitle'.tr(
                              namedArgs: {'identifier': args.identifier},
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          const SizedBox(height: 24),
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
                          const SizedBox(height: 24),
                          BlocBuilder<ForgotPasswordBloc, ForgotPasswordState>(
                            builder: (context, state) {
                              final isLoading =
                                  state is ForgotPasswordOtpVerifyLoadingState;
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
                          const SizedBox(height: 16),
                          BlocBuilder<ForgotPasswordBloc, ForgotPasswordState>(
                            builder: (context, fpState) {
                              return BlocBuilder<OtpUiCubit, OtpUiState>(
                                buildWhen: (previous, current) =>
                                    previous.secondsRemaining !=
                                    current.secondsRemaining,
                                builder: (context, otpUi) {
                                  final resendLoading = fpState
                                      is ForgotPasswordOtpResendLoadingState;
                                  final canResend =
                                      otpUi.secondsRemaining == 0 &&
                                          !resendLoading;

                                  if (canResend) {
                                    return AppButton(
                                      label: 'otp.resend'.tr(),
                                      type: AppButtonType.transparent,
                                      onPressed: () {
                                        context.read<ForgotPasswordBloc>().add(
                                              ForgotPasswordResendOtpEvent(
                                                args.identifier,
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
                          const SizedBox(height: 16),
                          AppButton(
                            label: 'otp.back_to_login'.tr(),
                            type: AppButtonType.transparent,
                            onPressed: () {
                              if (onBackToLogin != null) {
                                onBackToLogin!();
                              } else {
                                context.go(AuthRoutes.login);
                              }
                            },
                          ),
                          const SizedBox(height: 32),
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
    context.read<ForgotPasswordBloc>().add(
          ForgotPasswordVerifyOtpEvent(
            args.identifier,
            int.parse(otpController.text.trim()),
          ),
        );
  }
}
