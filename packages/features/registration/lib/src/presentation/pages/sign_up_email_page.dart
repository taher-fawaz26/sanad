import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
import 'package:registration/src/presentation/cubit/registration_cubit.dart';
import 'package:registration/src/presentation/widgets/registration_header.dart';

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

/// Step 1 — email entry (Sign Up entry point).
///
/// Requests a one-time code via the shared auth OTP flow, then hands off to the
/// shared OTP screen. Figma: `Signup` (`2142:14088`).
class SignUpEmailPage extends HookWidget {
  const SignUpEmailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController(
      text: context.read<RegistrationCubit>().state.email,
    );
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final colors = context.appColors;
    final typography = context.appTypography;

    void submit() {
      if (!(formKey.currentState?.validate() ?? false)) return;
      final email = controller.text.trim();
      context.read<RegistrationCubit>().setEmail(email);
      context.read<AuthBloc>().add(AuthRequestOtpEvent(email));
    }

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthOtpSentState) {
          context.push(AuthRoutes.otp, extra: state.email);
        } else if (state is AuthOtpRequestFailureState) {
          showAppErrorSnackbar(
            context: context,
            title: state.failure.localizedMessage(),
          );
        }
      },
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RegistrationHeader(
              title: 'registration.sign_up_title'.tr(),
              subtitle: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'registration.sign_up_subtitle_prefix'.tr()),
                    TextSpan(
                      text: 'registration.sign_up_email_word'.tr(),
                      style: TextStyle(color: colors.primary),
                    ),
                    TextSpan(text: 'registration.sign_up_subtitle_suffix'.tr()),
                  ],
                ),
              ),
            ),
            SizedBox(height: responsiveDimension(AppSpacing.xxxl)),
            AppTextField(
              controller: controller,
              label: 'registration.email_label'.tr(),
              hint: 'registration.email_hint'.tr(),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onSubmitted: (_) => submit(),
              validator: (value) {
                if (!EmailValidator.isValid(value?.trim())) {
                  return 'registration.email_invalid'.tr();
                }
                return null;
              },
            ),
            SizedBox(height: responsiveDimension(AppSpacing.xl)),
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final isLoading = state is AuthOtpRequestLoadingState;
                return AppButton(
                  label: 'registration.continue'.tr(),
                  isLoading: isLoading,
                  onPressed: isLoading ? null : submit,
                );
              },
            ),
            SizedBox(height: responsiveDimension(AppSpacing.xl)),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsiveDimension(AppSpacing.md),
                  ),
                  child: Text(
                    'registration.or'.tr(),
                    style: typography.smallNormal.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            SizedBox(height: responsiveDimension(AppSpacing.md)),
            Center(
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
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => context.pop(),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: responsiveDimension(AppSpacing.xl)),
            OutlinedButton.icon(
              onPressed: () {
                // TODO(registration): trigger Google OAuth
              },
              icon: SvgPicture.string(_googleLogoSvg, width: 20, height: 20),
              label: Text('registration.google'.tr()),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.textPrimary,
                side: BorderSide(color: colors.border),
                padding: EdgeInsets.symmetric(
                  vertical: responsiveDimension(14),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.circularMd,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
