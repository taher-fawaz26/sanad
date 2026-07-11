import 'package:auth/src/domain/enums/user_type.dart';
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

enum RegisterIdentifierMode { phone, email }

/// Registration screen — stays in the auth feature.
class RegisterPage extends HookWidget {
  const RegisterPage({
    super.key,
    this.onRegistered,
    this.onSignIn,
  });

  /// Called after successful register with identifier + mode for OTP routing.
  final void Function(String identifier, RegisterIdentifierMode mode)?
  onRegistered;
  final VoidCallback? onSignIn;

  @override
  Widget build(BuildContext context) {
    final identifierController = useTextEditingController();
    final passwordController = useTextEditingController();
    final confirmController = useTextEditingController();
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final mode = useState(RegisterIdentifierMode.phone);

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthRegisterFailureState) {
          showAppSnackbar(context: context, title: state.message);
        } else if (state is AuthRegisterSuccessState) {
          showAppSnackbar(
            context: context,
            title: state.message.tr(),
            color: AppSnackbarColor.primary,
          );
          onRegistered?.call(
            identifierController.text.trim(),
            mode.value,
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
                        const SizedBox(height: 48),
                        AppSection(
                          title: 'auth.register_title'.tr(),
                          caption: 'auth.register_caption'.tr(),
                          size: AppSectionSize.large,
                          padding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 32),
                        AppSegmentedControl(
                          segments: [
                            'auth.phone'.tr(),
                            'auth.email'.tr(),
                          ],
                          selectedIndex:
                              mode.value == RegisterIdentifierMode.phone
                              ? 0
                              : 1,
                          onChanged: (index) {
                            mode.value = index == 0
                                ? RegisterIdentifierMode.phone
                                : RegisterIdentifierMode.email;
                            identifierController.clear();
                          },
                        ),
                        const SizedBox(height: 24),
                        AppTextField(
                          controller: identifierController,
                          label: mode.value == RegisterIdentifierMode.phone
                              ? 'auth.phone'.tr()
                              : 'auth.email'.tr(),
                          hint: mode.value == RegisterIdentifierMode.phone
                              ? 'auth.phone_hint'.tr()
                              : 'auth.email_hint'.tr(),
                          keyboardType:
                              mode.value == RegisterIdentifierMode.phone
                              ? TextInputType.phone
                              : TextInputType.emailAddress,
                          validator: (value) {
                            if (value?.trim().isEmpty ?? true) {
                              return 'auth.field_required'.tr();
                            }
                            if (mode.value == RegisterIdentifierMode.email &&
                                !EmailValidator.isValid(value!.trim())) {
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
                            if (value!.length < PasswordValidator.minLength) {
                              return 'auth.password_too_short'.tr();
                            }
                            if (!PasswordValidator.isValid(value.trim())) {
                              return 'auth.invalid_password'.tr();
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
                        BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) {
                            final isLoading = state is AuthRegisterLoadingState;
                            return AppButton(
                              label: 'auth.create_account'.tr(),
                              isLoading: isLoading,
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      if (!(formKey.currentState?.validate() ??
                                          false)) {
                                        return;
                                      }
                                      context.read<AuthBloc>().add(
                                        AuthRegisterEvent(
                                          identifierController.text.trim(),
                                          passwordController.text,
                                          UserType.provider,
                                        ),
                                      );
                                    },
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                'auth.already_have_account'.tr(),
                                style: context.appTypography.regularNormal
                                    .copyWith(
                                      color: context.appColors.textSecondary,
                                    ),
                              ),
                            ),
                            AppButton(
                              label: 'auth.login'.tr(),
                              type: AppButtonType.transparent,
                              size: AppButtonSize.small,
                              onPressed: () {
                                if (onSignIn != null) {
                                  onSignIn!();
                                } else {
                                  context.go(AuthRoutes.login);
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
}
