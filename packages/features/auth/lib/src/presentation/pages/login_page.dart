import 'package:auth/src/presentation/bloc/auth/auth_bloc.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:localization/localization.dart';

/// Figma `sign in` (`3026:19575`) — passwordless email sign-in.
const _googleLogoSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path fill="#4285F4"
    d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
  <path fill="#34A853"
    d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
  <path fill="#FBBC05"
    d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l3.66-2.84z"/>
  <path fill="#EA4335"
    d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
</svg>
''';

/// Sign-in screen — the user enters only their email; a one-time code is then
/// sent and verified on the shared OTP screen.
class LoginPage extends HookWidget {
  const LoginPage({
    required this.onOtpSent,
    super.key,
    this.onRegister,
  });

  /// Called once the OTP has been dispatched — navigate to the OTP screen.
  final ValueChanged<String> onOtpSent;

  /// Opens the sign-up flow. When null, the "Sign up" row is hidden (apps
  /// without a registration flow).
  final VoidCallback? onRegister;

  @override
  Widget build(BuildContext context) {
    final emailController = useTextEditingController();
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final colors = context.appColors;
    final typography = context.appTypography;

    void submit() {
      if (!(formKey.currentState?.validate() ?? false)) return;
      context.read<AuthBloc>().add(
            AuthRequestOtpEvent(emailController.text.trim()),
          );
    }

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthOtpSentState) {
          onOtpSent(state.email);
        } else if (state is AuthOtpRequestFailureState) {
          showAppErrorSnackbar(
            context: context,
            title: state.failure.localizedMessage(),
          );
        }
      },
      child: AuthScreenShell(
        title: 'auth.login_title'.tr(),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'auth.login_title'.tr(),
                textAlign: TextAlign.center,
                style: typography.title2.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              SizedBox(height: responsiveDimension(AppSpacing.sm)),
              Text(
                'auth.login_caption'.tr(),
                textAlign: TextAlign.center,
                style: typography.regularNormal.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              SizedBox(height: responsiveDimension(AppSpacing.xxxl)),
              AppTextField(
                controller: emailController,
                label: 'auth.email'.tr(),
                hint: 'auth.email_hint'.tr(),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onSubmitted: (_) => submit(),
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
              SizedBox(height: responsiveDimension(AppSpacing.xl)),
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  final isLoading = state is AuthOtpRequestLoadingState;
                  return AppButton(
                    onPressed: isLoading ? null : submit,
                    label: 'auth.continue_button'.tr(),
                    isLoading: isLoading,
                  );
                },
              ),
              if (onRegister != null) ...[
                SizedBox(height: responsiveDimension(AppSpacing.xl)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'auth.no_account'.tr(),
                      style: typography.regularNormal.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    AppButton(
                      label: 'auth.register'.tr(),
                      type: AppButtonType.transparent,
                      size: AppButtonSize.small,
                      onPressed: onRegister,
                    ),
                  ],
                ),
              ],
              SizedBox(height: responsiveDimension(AppSpacing.xl)),
              Row(
                children: [
                  const Expanded(child: AppDivider()),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: responsiveDimension(AppSpacing.md),
                    ),
                    child: Text(
                      'auth.or'.tr(),
                      style: typography.regularNormal.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  const Expanded(child: AppDivider()),
                ],
              ),
              SizedBox(height: responsiveDimension(AppSpacing.xl)),
              OutlinedButton.icon(
                onPressed: () {
                  // TODO(auth): trigger Google OAuth
                },
                icon: SvgPicture.string(_googleLogoSvg, width: 24, height: 24),
                label: Text(
                  'auth.google'.tr(),
                  style: typography.regularNormal.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.textPrimary,
                  side: BorderSide(color: colors.border),
                  padding: EdgeInsets.symmetric(
                    vertical: responsiveDimension(AppSpacing.lg),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.circularMd,
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
