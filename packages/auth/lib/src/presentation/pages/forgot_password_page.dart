import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_app/src/core/localization/localization_x.dart';
import 'package:sanad_app/src/core/routes/app_route_path.dart';
import 'package:sanad_app/src/core/themes/tokens.dart';
import 'package:sanad_app/src/core/ui/appbar/app_auth_app_bar.dart';
import 'package:sanad_app/src/core/ui/buttons/buttons.dart';
import 'package:sanad_app/src/core/ui/form_fields/form_fields.dart';
import 'package:sanad_app/src/core/ui/layout/app_layout.dart';
import 'package:sanad_app/src/core/ui/snackbar_widget.dart';
import 'package:sanad_app/src/core/ui/typography/app_text.dart';
import 'package:sanad_app/src/core/utils/otp_args.dart';
import 'package:sanad_app/src/features/auth/presentation/bloc/auth/auth_bloc.dart';

import '../widgets/auth_title_section.dart';

/// Step 1 of password recovery: submit email to receive OTP.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          (current is AuthForgotPasswordOtpSentState &&
              previous is AuthForgotPasswordRequestLoadingState) ||
          (current is AuthForgotPasswordRequestFailureState &&
              previous is AuthForgotPasswordRequestLoadingState),
      listener: (context, state) {
        if (state is AuthForgotPasswordRequestFailureState) {
          AppSnackBar.show(
            context,
            message: context.trOrRaw(state.message),
            variant: SnackBarVariant.error,
          );
        } else if (state is AuthForgotPasswordOtpSentState) {
          final email = _formKey.currentState?.instantValue['email'] as String?;
          final identifier = email?.trim() ?? '';
          if (identifier.isEmpty) return;
          AppSnackBar.show(
            context,
            message: context.tr('auth_forgot.otp_sent'),
            variant: SnackBarVariant.success,
          );
          context.pushNamed(
            AppRoute.otp.name,
            extra: OtpArgs(
              identifier: identifier,
              type: IdentifierType.email,
              flow: OtpFlow.forgotPassword,
            ),
          );
        }
      },
      child: BlocSelector<AuthBloc, AuthState, bool>(
        selector: (s) => s is AuthForgotPasswordRequestLoadingState,
        builder: (context, isLoading) {
          return AppLayout(
            appBar: const AppAuthAppBar(),
            sliverLayout: true,
            body: FormBuilder(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpacing.xl,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthTitleSection(
                    title: context.tr('auth_forgot.title'),
                    subtitle: context.tr('auth_forgot.subtitle'),
                  ),
                  AppTextFormField.email(
                    formFieldName: 'email',
                    label: context.tr('auth_shared.email'),
                    hint: context.tr('auth_shared.hint_email'),
                    size: FieldSize.small,
                  ),
                  AppButton.expand(
                    label: context.tr('auth_forgot.send_code'),
                    styleType: ButtonStyleType.primary,
                    isLoading: isLoading,
                    onPressed: isLoading
                        ? null
                        : () {
                            if (_formKey.currentState?.saveAndValidate() ??
                                false) {
                              final email =
                                  _formKey.currentState?.instantValue['email']
                                      as String?;
                              if (email != null && email.trim().isNotEmpty) {
                                context.read<AuthBloc>().add(
                                  AuthForgotPasswordRequestEvent(email),
                                );
                              }
                            }
                          },
                  ),
                  Center(
                    child: GestureDetector(
                      onTap: isLoading
                          ? null
                          : () => context.goNamed(AppRoute.login.name),
                      child: AppText.labelLarge(
                        context.tr('auth_forgot.back_to_login'),
                        tone: AppTextTone.brand,
                      ),
                    ),
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
