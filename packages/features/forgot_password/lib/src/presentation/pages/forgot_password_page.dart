import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forgot_password/src/presentation/bloc/forgot_password_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
import 'package:otp/otp.dart';

/// Step 1 of password recovery: submit email to receive OTP.
class ForgotPasswordPage extends HookWidget {
  const ForgotPasswordPage({
    super.key,
    this.onBackToLogin,
    this.onOtpSent,
  });

  final VoidCallback? onBackToLogin;
  final ValueChanged<OtpArgs>? onOtpSent;

  @override
  Widget build(BuildContext context) {
    final emailController = useTextEditingController();
    final formKey = useMemoized(GlobalKey<FormState>.new);

    return BlocListener<ForgotPasswordBloc, ForgotPasswordState>(
      listenWhen: (previous, current) =>
          current is ForgotPasswordOtpSentState ||
          current is ForgotPasswordRequestFailureState,
      listener: (context, state) {
        if (state is ForgotPasswordRequestFailureState) {
          showAppErrorSnackbar(
            context: context,
            title: state.failure.localizedMessage(),
          );
        } else if (state is ForgotPasswordOtpSentState) {
          final identifier = emailController.text.trim();
          if (identifier.isEmpty) return;
          showAppSnackbar(
            context: context,
            title: 'forgot_password.otp_sent'.tr(),
            color: AppSnackbarColor.primary,
          );
          final args = OtpArgs(
            identifier: identifier,
            type: IdentifierType.email,
            flow: OtpFlow.forgotPassword,
          );
          if (onOtpSent != null) {
            onOtpSent!(args);
          } else {
            context.push(OtpRoutes.otp, extra: args);
          }
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
                        const SizedBox(height: 48),
                        AppSection(
                          title: 'forgot_password.title'.tr(),
                          caption: 'forgot_password.subtitle'.tr(),
                          padding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 32),
                        AppTextField(
                          controller: emailController,
                          label: 'auth.email'.tr(),
                          hint: 'auth.email_hint'.tr(),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value?.trim().isEmpty ?? true) {
                              return 'auth.field_required'.tr();
                            }
                            if (!EmailValidator.isValid(value!.trim())) {
                              return 'auth.invalid_email'.tr();
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        BlocBuilder<ForgotPasswordBloc, ForgotPasswordState>(
                          builder: (context, state) {
                            final isLoading =
                                state is ForgotPasswordRequestLoadingState;
                            return AppButton(
                              label: 'forgot_password.send_code'.tr(),
                              isLoading: isLoading,
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      if (!(formKey.currentState?.validate() ??
                                          false)) {
                                        return;
                                      }
                                      context.read<ForgotPasswordBloc>().add(
                                            ForgotPasswordRequestEvent(
                                              emailController.text.trim(),
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
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
