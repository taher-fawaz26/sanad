import 'dart:async';

import 'package:auth/src/presentation/bloc/auth/auth_bloc.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';

const _kResendCooldown = 60;

/// Shared passwordless OTP screen (Figma `sign in` / OTP, `3026:19710`).
///
/// Reached identically from Sign In and Sign Up. Verifies the emailed code via
/// [AuthBloc]; on success it either hands off to [onAuthenticated] (existing
/// user) or [onOnboarding] (new user continuing registration).
class EmailOtpPage extends HookWidget {
  const EmailOtpPage({
    required this.email,
    required this.onAuthenticated,
    required this.onOnboarding,
    super.key,
    this.onChangeEmail,
  });

  final String email;
  final VoidCallback onAuthenticated;
  final void Function(String email, String onboardingToken) onOnboarding;

  /// Back / "change email" action. Defaults to popping the OTP screen.
  final VoidCallback? onChangeEmail;

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController();
    final secondsLeft = useState(_kResendCooldown);
    final canResend = useState(false);
    final colors = context.appColors;
    final typography = context.appTypography;

    useEffect(() {
      final timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (secondsLeft.value <= 1) {
          t.cancel();
          secondsLeft.value = 0;
          canResend.value = true;
        } else {
          secondsLeft.value--;
        }
      });
      return timer.cancel;
    }, const []);

    void changeEmail() {
      if (onChangeEmail != null) {
        onChangeEmail!();
      } else if (context.canPop()) {
        context.pop();
      }
    }

    void submit() {
      if (controller.text.trim().length < kDefaultOtpLength) {
        showAppErrorSnackbar(
          context: context,
          title: 'auth.otp_invalid'.tr(),
        );
        return;
      }
      context.read<AuthBloc>().add(
            AuthVerifyOtpEvent(email: email, otp: controller.text.trim()),
          );
    }

    void resend() {
      if (!canResend.value) return;
      secondsLeft.value = _kResendCooldown;
      canResend.value = false;
      controller.clear();
      context.read<AuthBloc>().add(AuthRequestOtpEvent(email));
    }

    final minutes = (secondsLeft.value ~/ 60).toString().padLeft(2, '0');
    final seconds = (secondsLeft.value % 60).toString().padLeft(2, '0');

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        switch (state) {
          case AuthAuthenticatedState():
            onAuthenticated();
          case AuthOnboardingRequiredState(
              :final email,
              :final onboardingToken,
            ):
            onOnboarding(email, onboardingToken);
          case AuthOtpVerifyFailureState(:final failure):
            showAppErrorSnackbar(
              context: context,
              title: failure.localizedMessage(),
            );
          case AuthOtpSentState():
            showAppSnackbar(
              context: context,
              title: 'auth.otp_resent'.tr(),
              color: AppSnackbarColor.primary,
            );
          case AuthOtpRequestFailureState(:final failure):
            showAppErrorSnackbar(
              context: context,
              title: failure.localizedMessage(),
            );
          default:
            break;
        }
      },
      child: AuthScreenShell(
        onBack: changeEmail,
        title: 'auth.otp_title'.tr(),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'auth.otp_title'.tr(),
              textAlign: TextAlign.center,
              style: typography.title2.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            SizedBox(height: responsiveDimension(AppSpacing.sm)),
            Text.rich(
              textAlign: TextAlign.center,
              TextSpan(
                style: typography.regularNormal.copyWith(
                  color: colors.textSecondary,
                ),
                children: [
                  TextSpan(text: '${'auth.otp_subtitle'.tr()}\n'),
                  TextSpan(
                    text: email,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const TextSpan(text: ' '),
                  TextSpan(
                    text: 'auth.change'.tr(),
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    recognizer: TapGestureRecognizer()..onTap = changeEmail,
                  ),
                ],
              ),
            ),
            SizedBox(height: responsiveDimension(AppSpacing.xxxl)),
            Center(
              child: AppOtpField(
                controller: controller,
                autofocus: true,
                onCompleted: (_) => submit(),
              ),
            ),
            SizedBox(height: responsiveDimension(AppSpacing.xl)),
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final isLoading = state is AuthOtpVerifyLoadingState;
                return AppButton(
                  label: 'auth.verify'.tr(),
                  isLoading: isLoading,
                  onPressed: isLoading ? null : submit,
                );
              },
            ),
            SizedBox(height: responsiveDimension(AppSpacing.xl)),
            if (!canResend.value)
              Center(
                child: Text(
                  '$minutes:$seconds',
                  style: typography.regularNormal.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            SizedBox(height: responsiveDimension(AppSpacing.xl)),
            Center(
              child: Text.rich(
                TextSpan(
                  style: typography.regularNormal.copyWith(
                    color: colors.textSecondary,
                  ),
                  children: [
                    TextSpan(text: 'auth.otp_not_received'.tr()),
                    TextSpan(
                      text: 'auth.resend'.tr(),
                      style: TextStyle(
                        color: canResend.value
                            ? colors.primary
                            : colors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                      recognizer: canResend.value
                          ? (TapGestureRecognizer()..onTap = resend)
                          : null,
                    ),
                  ],
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
