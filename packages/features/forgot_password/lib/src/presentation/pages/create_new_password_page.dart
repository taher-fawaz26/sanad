import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forgot_password/src/models/create_new_password_args.dart';
import 'package:forgot_password/src/presentation/bloc/forgot_password_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';

/// Create a new password after forgot-password OTP verification.
class CreateNewPasswordPage extends HookWidget {
  const CreateNewPasswordPage({
    required this.args,
    super.key,
    this.onSuccess,
  });

  final CreateNewPasswordArgs args;
  final VoidCallback? onSuccess;

  @override
  Widget build(BuildContext context) {
    final passwordController = useTextEditingController();
    final confirmController = useTextEditingController();
    final formKey = useMemoized(GlobalKey<FormState>.new);

    return BlocListener<ForgotPasswordBloc, ForgotPasswordState>(
      listenWhen: (previous, current) =>
          current is ForgotPasswordResetSuccessState ||
          current is ForgotPasswordResetFailureState,
      listener: (context, state) {
        if (state is ForgotPasswordResetFailureState) {
          showAppErrorSnackbar(
            context: context,
            title: state.failure.localizedMessage(),
          );
        } else if (state is ForgotPasswordResetSuccessState) {
          showAppSnackbar(
            context: context,
            title: 'forgot_password.reset_success'.tr(),
            color: AppSnackbarColor.primary,
          );
          if (onSuccess != null) {
            onSuccess!();
          } else {
            context.go(AuthRoutes.login);
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
                          title: 'forgot_password.create_title'.tr(),
                          caption: 'forgot_password.create_subtitle'.tr(),
                          padding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 32),
                        AppTextField(
                          controller: passwordController,
                          label: 'auth.password'.tr(),
                          hint: 'auth.password_hint'.tr(),
                          obscureText: true,
                          validator: (value) {
                            if (value?.trim().isEmpty ?? true) {
                              return 'auth.field_required'.tr();
                            }
                            if (value!.length < 6) {
                              return 'auth.password_too_short'.tr();
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: confirmController,
                          label: 'auth.confirm_password'.tr(),
                          hint: 'auth.confirm_password_hint'.tr(),
                          obscureText: true,
                          validator: (value) {
                            if (value?.trim().isEmpty ?? true) {
                              return 'auth.field_required'.tr();
                            }
                            if (value != passwordController.text) {
                              return 'auth.password_mismatch'.tr();
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        BlocBuilder<ForgotPasswordBloc, ForgotPasswordState>(
                          builder: (context, state) {
                            final isLoading =
                                state is ForgotPasswordResetLoadingState;
                            return AppButton(
                              label: 'forgot_password.reset'.tr(),
                              isLoading: isLoading,
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      if (!(formKey.currentState?.validate() ??
                                          false)) {
                                        return;
                                      }
                                      context.read<ForgotPasswordBloc>().add(
                                            ForgotPasswordResetEvent(
                                              args.identifier,
                                              passwordController.text,
                                            ),
                                          );
                                    },
                            );
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
