import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_app/src/core/themes/tokens.dart';
import 'package:sanad_app/src/core/ui/appbar/app_auth_app_bar.dart';
import 'package:sanad_app/src/core/ui/buttons/buttons.dart';
import 'package:sanad_app/src/core/ui/form_fields/form_fields.dart';
import 'package:sanad_app/src/core/ui/layout/app_layout.dart';
import 'package:sanad_app/src/core/ui/snackbar_widget.dart';
import 'package:sanad_app/src/core/utils/create_new_password_args.dart';
import 'package:sanad_app/src/core/utils/validators/validators.dart';
import 'package:sanad_app/src/features/auth/presentation/bloc/auth/auth_bloc.dart';

import '../../../../core/localization/form_validation_x.dart';
import '../../../../core/localization/localization_x.dart';
import '../../../../core/routes/app_route_path.dart';
import '../widgets/auth_title_section.dart';

/// Screen for creating a new password after forgot-password OTP verification.
class CreateNewPasswordPage extends StatefulWidget {
  const CreateNewPasswordPage({super.key, required this.args});

  final CreateNewPasswordArgs args;

  @override
  State<CreateNewPasswordPage> createState() => _CreateNewPasswordPageState();
}

class _CreateNewPasswordPageState extends State<CreateNewPasswordPage> {
  final GlobalKey<FormBuilderState> formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          (current is AuthResetPasswordSuccessState &&
              previous is AuthResetPasswordLoadingState) ||
          (current is AuthResetPasswordFailureState &&
              previous is AuthResetPasswordLoadingState),
      listener: (context, state) {
        if (state is AuthResetPasswordFailureState) {
          AppSnackBar.show(
            context,
            message: context.trOrRaw(state.message),
            variant: SnackBarVariant.error,
          );
        } else if (state is AuthResetPasswordSuccessState) {
          AppSnackBar.show(
            context,
            message: context.tr('auth_password.reset_success'),
            variant: SnackBarVariant.success,
          );
          context.goNamed(AppRoute.login.name);
        }
      },
      child: BlocSelector<AuthBloc, AuthState, bool>(
        selector: (s) => s is AuthResetPasswordLoadingState,
        builder: (context, isLoading) {
          return AppLayout(
            appBar: const AppAuthAppBar(),
            sliverLayout: true,
            body: FormBuilder(
              key: formKey,
              child: Column(
                spacing: AppSpacing.xl,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AuthTitleSection(
                    title: context.tr('auth_password.create_title'),
                    subtitle: context.tr('auth_password.create_subtitle'),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  AppTextFormField.password(
                    formFieldName: 'password',
                    label: context.tr('auth_shared.password'),
                    hint: context.tr('auth_shared.hint_password'),
                    size: FieldSize.small,
                    validator: ValidationUtils.compose([
                      ValidationUtils.required(
                        messageKey: context.formRequired,
                      ),
                      ValidationUtils.password(
                        messageKey: context.formPasswordPolicy,
                      ),
                    ]),
                  ),
                  AppTextFormField.password(
                    formFieldName: 'confirm_password',
                    label: context.tr('auth_shared.confirm_password'),
                    hint: context.tr('auth_shared.hint_confirm_password'),
                    size: FieldSize.small,
                    validator: ValidationUtils.compose([
                      ValidationUtils.required(
                        messageKey: context.formRequired,
                      ),
                      (value) {
                        final current = formKey
                            .currentState
                            ?.instantValue['password']
                            ?.toString();
                        if (value != current) {
                          return context.tr('auth_password.mismatch');
                        }
                        return null;
                      },
                    ]),
                  ),
                  AppButton.expand(
                    label: context.tr('auth_password.submit'),
                    styleType: ButtonStyleType.primary,
                    isLoading: isLoading,
                    onPressed: isLoading
                        ? null
                        : () {
                            if (formKey.currentState?.saveAndValidate() ??
                                false) {
                              final password =
                                  formKey.currentState?.instantValue['password']
                                      as String?;
                              if (password != null) {
                                context.read<AuthBloc>().add(
                                  AuthResetPasswordEvent(
                                    widget.args.identifier,
                                    password,
                                  ),
                                );
                              }
                            }
                          },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
