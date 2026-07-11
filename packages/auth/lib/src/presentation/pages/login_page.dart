import 'package:auth/src/presentation/bloc/auth/auth_bloc.dart';
import 'package:auth/src/presentation/widgets/app_header.dart';
import 'package:auth/src/routes/auth_routes.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';

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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: context.appColors.error,
            ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 48),
                        AppSection(
                          title: 'auth.login_title'.tr(),
                          caption: 'auth.login_caption'.tr(),
                          size: AppSectionSize.large,
                        ),
                        const SizedBox(height: 32),
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
                        const SizedBox(height: 24),
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
                                !_isValidEmail(value!)) {
                              return 'auth.invalid_email'.tr();
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
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
                        const SizedBox(height: 8),
                        // Forgot password
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: AppButton(
                            label: 'auth.forgot_password'.tr(),
                            type: AppButtonType.transparent,
                            size: AppButtonSize.small,
                            onPressed: () {
                              if (onForgotPassword != null) {
                                onForgotPassword!();
                              } else {
                                context.push('/forgot-password');
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
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
                        const SizedBox(height: 16),
                        // Register link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'auth.no_account'.tr(),
                              style: TextStyle(
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

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
