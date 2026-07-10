import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_app/src/core/routes/app_route_path.dart';
import 'package:sanad_app/src/core/ui/appbar/app_auth_app_bar.dart';
import 'package:sanad_app/src/core/ui/buttons/buttons.dart';
import 'package:sanad_app/src/core/ui/form/sanad_form.dart';
import 'package:sanad_app/src/core/ui/layout/app_layout.dart';
import 'package:sanad_app/src/core/ui/snackbar_widget.dart';
import 'package:sanad_app/src/core/utils/otp_args.dart';
import 'package:sanad_app/src/features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'package:sanad_app/src/features/auth/presentation/widgets/register_form_widget.dart';

import '../../../../core/localization/localization_x.dart';
import '../../../../core/themes/colors/app_colors.dart';
import '../../../../core/themes/tokens.dart';
import '../../../../core/themes/typography/app_typography.dart';
import '../../domain/enums/user_type.dart';
import '../widgets/auth_title_section.dart';
import '../widgets/social_login_buttons.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthRegisterFailureState) {
          AppSnackBar.show(
            context,
            message: context.trOrRaw(state.message),
            variant: SnackBarVariant.error,
          );
        } else if (state is AuthRegisterSuccessState) {
          AppSnackBar.show(
            context,
            message: context.trOrRaw(state.message),
            variant: SnackBarVariant.success,
          );

          // Determine identifier and its type from the form values.
          final emailValue =
              _formKey.currentState?.instantValue['email'] as String?;
          final phoneValue =
              _formKey.currentState?.instantValue['phone'] as String?;

          final String identifier =
              (emailValue?.isNotEmpty == true ? emailValue : phoneValue) ?? '';
          final IdentifierType type = emailValue?.isNotEmpty == true
              ? IdentifierType.email
              : IdentifierType.phone;

          context.pushNamed(
            AppRoute.otp.name,
            extra: OtpArgs(identifier: identifier, type: type),
          );
        }
      },
      child: AppLayout(
        appBar: const AppAuthAppBar(),
        sliverLayout: true,
        body: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.xl,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthTitleSection(
              title: context.tr('auth_register.title'),
              subtitle: context.tr('auth_register.subtitle'),
            ),

            // 3. Email / Mobile toggle
            RegisterFormWidget(formKey: _formKey),

            // 7. Sign In Button
            BlocBuilder<AuthBloc, AuthState>(
              buildWhen: (previous, current) =>
                  current is AuthRegisterLoadingState ||
                  previous is AuthRegisterLoadingState,
              builder: (context, state) {
                return AppButton.expand(
                  label: context.tr('auth_register.create_account'),
                  styleType: ButtonStyleType.primary,
                  isLoading: state is AuthRegisterLoadingState,
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      final email =
                          _formKey.currentState?.instantValue['email'];
                      context.read<AuthBloc>().add(
                        AuthRegisterEvent(
                          email ?? _formKey.currentState?.instantValue["phone"],
                          _formKey.currentState?.instantValue['password'] ?? '',
                          // This app serves providers. CLIENT support can be
                          // added later when a type-selection UI is built.
                          UserType.provider,
                        ),
                      );
                    }
                  },
                );
              },
            ),

            // 8. Social Login
            SocialLoginButtons(
              onAppleSignInPressed: () {},
              onGoogleSignInPressed: () {},
            ),
            // 9. Footer Text
            Center(
              child: RichText(
                text: TextSpan(
                  text: context.tr('auth_register.already_have_account'),
                  style: context.appTypography.bodyMedium.copyWith(
                    color: context.appColors.textSecondary,
                  ),
                  children: [
                    TextSpan(
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          context.goNamed(AppRoute.login.name);
                        },
                      text: context.tr('auth_register.sign_in_link'),
                      style: context.appTypography.labelMedium.copyWith(
                        color: context.appColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
