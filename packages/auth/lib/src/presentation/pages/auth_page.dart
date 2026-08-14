import 'package:auth/src/domain/enums/auth_flow_intent.dart';
import 'package:auth/src/presentation/bloc/auth/auth_bloc.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:localization/localization.dart';
import 'package:shared_ui/shared_ui.dart';

/// Figma `sign in` (`3026:19575`) and `Signup` (`2142:14088`).
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

/// Passwordless email entry for sign-in and sign-up on a single screen.
///
/// The user toggles between modes in-page; copy and validation rules follow
/// [isLogin].
class AuthPage extends HookWidget {
  const AuthPage({
    required this.onOtpSent,
    super.key,
    this.initialIsLogin = true,
    this.onAuthenticated,
    this.onOnboarding,
  });

  /// Starting mode when the page opens (`true` = sign in, `false` = sign up).
  final bool initialIsLogin;

  /// Called once the OTP has been dispatched — navigate to the OTP screen.
  /// Carries [AuthFlowIntent] so the OTP screen verifies against the right
  /// endpoint (`login/verify` vs `signup/verify`).
  final void Function(String email, AuthFlowIntent intent) onOtpSent;

  /// Called when Google Sign-In completes for an existing user.
  final VoidCallback? onAuthenticated;

  /// Called when Google Sign-In results in a new user needing onboarding.
  final void Function(String email, String onboardingToken)? onOnboarding;

  @override
  Widget build(BuildContext context) {
    final isLogin = useState(initialIsLogin);
    final emailController = useTextEditingController();
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final colors = context.appColors;
    final typography = context.appTypography;

    void toggleMode() => isLogin.value = !isLogin.value;

    AuthFlowIntent currentIntent() =>
        isLogin.value ? AuthFlowIntent.signIn : AuthFlowIntent.createAccount;

    void submit() {
      if (!(formKey.currentState?.validate() ?? false)) return;
      // Explicit Sign in / Create account choice (product decision): the
      // matching endpoint is called directly — no `validate-info` probe, no
      // silent auto-branch. 404 (login, unknown email) / 409 (signup, email
      // already registered) surface as real errors.
      context.read<AuthBloc>().add(
        AuthRequestOtpEvent(
          email: emailController.text.trim(),
          intent: currentIntent(),
        ),
      );
    }

    final shellTitle = isLogin.value
        ? 'auth.login_title'.tr()
        : 'registration.sign_up_title'.tr();

    final accountSwitchRow = isLogin.value
        ? Row(
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
                onPressed: toggleMode,
              ),
            ],
          )
        : Center(
            child: Text.rich(
              TextSpan(
                style: typography.regularNormal.copyWith(
                  color: colors.textSecondary,
                ),
                children: [
                  TextSpan(text: 'registration.have_account'.tr()),
                  TextSpan(
                    text: 'registration.sign_in'.tr(),
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    recognizer: TapGestureRecognizer()..onTap = toggleMode,
                  ),
                ],
              ),
            ),
          );

    final orDivider = Row(
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
    );

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (_, curr) =>
          curr is AuthOtpSentState ||
          curr is AuthOtpRequestFailureState ||
          curr is AuthAuthenticatedState ||
          curr is AuthOnboardingRequiredState ||
          curr is AuthGoogleSignInFailureState,
      listener: (context, state) {
        if (state is AuthOtpSentState) {
          onOtpSent(state.email, state.intent);
        } else if (state is AuthOtpRequestFailureState) {
          showAppErrorSnackbar(
            context: context,
            title: state.failure.localizedMessage(),
          );
        } else if (state is AuthAuthenticatedState) {
          onAuthenticated?.call();
        } else if (state is AuthOnboardingRequiredState) {
          onOnboarding?.call(state.email, state.onboardingToken);
        } else if (state is AuthGoogleSignInFailureState) {
          showAppErrorSnackbar(
            context: context,
            title: state.failure.localizedMessage(),
          );
        }
      },
      child: AuthScreenShell(
        title: shellTitle,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  shellTitle,
                  textAlign: TextAlign.center,
                  style: typography.title2.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                SizedBox(height: responsiveDimension(AppSpacing.sm)),
                if (isLogin.value)
                  Text(
                    'auth.login_caption'.tr(),
                    textAlign: TextAlign.center,
                    style: typography.regularNormal.copyWith(
                      color: colors.textSecondary,
                    ),
                  )
                else
                  Text.rich(
                    TextSpan(
                      style: typography.regularNormal.copyWith(
                        color: colors.textSecondary,
                      ),
                      children: [
                        TextSpan(
                          text: 'registration.sign_up_subtitle_prefix'.tr(),
                        ),
                        TextSpan(
                          text: 'registration.sign_up_email_word'.tr(),
                          style: TextStyle(color: colors.primary),
                        ),
                        TextSpan(
                          text: 'registration.sign_up_subtitle_suffix'.tr(),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                SizedBox(height: responsiveDimension(AppSpacing.xxxl)),
                AppTextField(
                  controller: emailController,
                  label: 'auth.email'.tr(),
                  hint: 'registration.email_hint'.tr(),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  onSubmitted: (_) => submit(),
                  validator: (value) {
                    if (!RequiredValidator.isValid(value)) {
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
                SizedBox(height: responsiveDimension(AppSpacing.xl)),
                if (isLogin.value) ...[
                  accountSwitchRow,
                  SizedBox(height: responsiveDimension(AppSpacing.xl)),
                ],
                orDivider,
                if (!isLogin.value) ...[
                  SizedBox(height: responsiveDimension(AppSpacing.xl)),
                  accountSwitchRow,
                ],
                SizedBox(height: responsiveDimension(AppSpacing.xl)),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final isLoading = state is AuthGoogleSignInLoadingState;
                    return OutlinedButton.icon(
                      onPressed: isLoading
                          ? null
                          : () => context.read<AuthBloc>().add(
                              AuthGoogleSignInEvent(currentIntent()),
                            ),
                      icon: SvgPicture.string(
                        _googleLogoSvg,
                        width: 24,
                        height: 24,
                      ),
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
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
