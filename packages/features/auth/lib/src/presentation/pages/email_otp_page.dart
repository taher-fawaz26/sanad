import 'dart:async';

import 'package:auth/src/domain/entities/auth_response_entity.dart';
import 'package:auth/src/domain/usecases/request_email_otp_usecase.dart';
import 'package:auth/src/domain/usecases/verify_email_otp_usecase.dart';
import 'package:auth/src/domain/verifiers/auth_otp_verifier.dart';
import 'package:auth/src/presentation/bloc/auth/auth_bloc.dart';
import 'package:auth/src/session/session_manager.dart';
import 'package:core/core.dart' show sl;
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
import 'package:shared_ui/shared_ui.dart';

const _kResendCooldown = 60;

/// Shared passwordless OTP screen (Figma `sign in` / OTP, `3026:19710`).
///
/// Reached identically from Sign In and Sign Up. Requesting the initial/
/// resend code still goes through [AuthBloc] (`AuthRequestOtpEvent`) — that
/// part of the flow is untouched. Verifying the code goes through
/// [AuthOtpVerifier] (the `otp` package's injected-verifier contract)
/// directly rather than a Bloc event, since `otp` owns the one verification
/// state machine in the app now — but this screen's own layout, header,
/// timer, and error/success handling are unchanged from before that
/// refactor. This is deliberate: the auth OTP screen is part of an already
/// approved onboarding design and must not be replaced by the generic OTP
/// sheet/page used everywhere else.
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
    final isVerifying = useState(false);
    final colors = context.appColors;
    final typography = context.appTypography;

    final verifier = useMemoized(
      () => AuthOtpVerifier(
        email: email,
        requestEmailOtp: sl<RequestEmailOtpUseCase>(),
        verifyEmailOtp: sl<VerifyEmailOtpUseCase>(),
        sessionManager: sl<SessionManager>(),
      ),
      [email],
    );

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

    Future<void> submit() async {
      if (controller.text.trim().length < kDefaultOtpLength) {
        showAppErrorSnackbar(
          context: context,
          title: 'auth.otp_invalid'.tr(),
        );
        return;
      }
      if (isVerifying.value) return;
      isVerifying.value = true;
      final result = await verifier.verifyCode(controller.text.trim()).run();
      if (!context.mounted) return;
      isVerifying.value = false;
      result.match(
        (failure) => showAppErrorSnackbar(
          context: context,
          title: failure.localizedMessage(),
        ),
        (response) {
          switch (response) {
            case AuthSessionEntity():
              onAuthenticated();
            case OnboardingAuthEntity(:final onboardingToken, :final user):
              onOnboarding(user.email, onboardingToken);
          }
        },
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
              AppButton(
                label: 'auth.verify'.tr(),
                isLoading: isVerifying.value,
                onPressed: isVerifying.value ? null : submit,
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
