import 'package:auth/src/presentation/bloc/auth/auth_bloc.dart';
import 'package:auth/src/presentation/widgets/app_header.dart';
import 'package:auth/src/routes/auth_routes.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';

enum AuthMode { phone, email }

class LoginPage extends HookWidget {
  const LoginPage({
    super.key,
    this.onAuthenticated,
    this.onForgotPassword,
    this.onRegister,
  });

  final VoidCallback? onAuthenticated;
  final VoidCallback? onForgotPassword;
  final VoidCallback? onRegister;

  @override
  Widget build(BuildContext context) {
    // Hooks for text controllers
    final identifierController = useTextEditingController();
    final passwordController = useTextEditingController();
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final authMode = useState<AuthMode>(AuthMode.phone);

    void submit() {
      if (!(formKey.currentState?.validate() ?? false)) return;
      context.read<AuthBloc>().add(
            AuthLoginEvent(
              identifierController.text.trim(),
              passwordController.text,
            ),
          );
    }

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthLoginSuccessState) {
          onAuthenticated?.call();
        } else if (state is AuthLoginFailureState) {
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
              // Header with logo and language selector
              const AppHeader(),
              const Divider(height: 1),
              // Login form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacingDp.xxl),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: AppSpacingDp.xxxxxl),
                        AppSection(
                          title: 'auth.login_title'.tr(),
                          caption: 'auth.login_caption'.tr(),
                          size: AppSectionSize.large,
                        ),
                        const SizedBox(height: AppSpacingDp.xxxl),
                        // Phone/Email toggle
                        AppSegmentedControl(
                          segments: [
                            'auth.phone'.tr(),
                            'auth.email'.tr(),
                          ],
                          selectedIndex: authMode.value == AuthMode.phone ? 0 : 1,
                          onChanged: (index) {
                            authMode.value =
                                index == 0 ? AuthMode.phone : AuthMode.email;
                            identifierController.clear();
                            passwordController.clear();
                          },
                        ),
                        const SizedBox(height: AppSpacingDp.xxl),
                        AppTextField(
                          controller: identifierController,
                          label: authMode.value == AuthMode.phone
                              ? 'auth.phone'.tr()
                              : 'auth.email'.tr(),
                          hint: authMode.value == AuthMode.phone
                              ? 'auth.phone_hint'.tr()
                              : 'auth.email_hint'.tr(),
                          keyboardType: authMode.value == AuthMode.phone
                              ? TextInputType.phone
                              : TextInputType.emailAddress,
                          validator: (value) {
                            if (value?.trim().isEmpty ?? true) {
                              return 'auth.field_required'.tr();
                            }
                            if (authMode.value == AuthMode.email &&
                                !EmailValidator.isValid(value!.trim())) {
                              return 'auth.invalid_email'.tr();
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacingDp.lg),
                        AppTextField(
                          controller: passwordController,
                          label: 'auth.password'.tr(),
                          hint: 'auth.password_hint'.tr(),
                          obscureText: true,
                          validator: (value) {
                            if (value?.trim().isEmpty ?? true) {
                              return 'auth.field_required'.tr();
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacingDp.sm),
                        // Forgot password
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: AppButton(
                            label: 'auth.forgot_password'.tr(),
                            type: AppButtonType.transparent,
                            size: AppButtonSize.small,
                            onPressed: onForgotPassword,
                          ),
                        ),
                        const SizedBox(height: AppSpacingDp.xxl),
                        BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) {
                            final isLoading = state is AuthLoginLoadingState;
                            return AppButton(
                              onPressed: isLoading ? null : submit,
                              label: 'auth.login'.tr(),
                              isLoading: isLoading,
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacingDp.lg),
                        // Register link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'auth.no_account'.tr(),
                              style: context.appTypography.regularNormal.copyWith(
                                color: context.appColors.textSecondary,
                              ),
                            ),
                            AppButton(
                              label: 'auth.register'.tr(),
                              type: AppButtonType.transparent,
                              size: AppButtonSize.small,
                              onPressed: () {
                                if (onRegister != null) {
                                  onRegister!();
                                } else {
                                  context.push(AuthRoutes.register);
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacingDp.xxxxxl),
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
