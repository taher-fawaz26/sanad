import 'dart:async';

import 'package:auth/src/domain/entities/auth_response_entity.dart';
import 'package:auth/src/domain/entities/login_result_entity.dart';
import 'package:auth/src/domain/enums/auth_account_status.dart';
import 'package:auth/src/domain/enums/auth_flow_intent.dart';
import 'package:auth/src/domain/usecases/get_current_user_usecase.dart';
import 'package:auth/src/domain/usecases/usecase_params.dart';
import 'package:auth/src/domain/usecases/verify_login_otp_usecase.dart';
import 'package:auth/src/domain/usecases/verify_signup_otp_usecase.dart';
import 'package:auth/src/presentation/bloc/auth/auth_bloc.dart';
import 'package:auth/src/routes/auth_routes.dart';
import 'package:auth/src/session/complete_active_login.dart';
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

/// Shared passwordless OTP screen (Figma `sign in` / OTP, `3026:19710`).
///
/// Reached identically from Sign In and Sign Up, disambiguated by [intent].
/// Requesting the initial/resend code still goes through [AuthBloc]
/// (`AuthRequestOtpEvent` / `AuthResendOtpEvent` /
/// `AuthResendInfoRequestedEvent`). Verifying the code calls the
/// signup/login verify use case directly (chosen by [intent]) rather than
/// through a Bloc event or the old shared `AuthOtpVerifier` — the two verify
/// endpoints have different response shapes (`OnboardingAuthResponseDto` vs
/// `LoginResponseDto`) that no longer fit a single generic verifier
/// contract, and calling the use cases straight from the page keeps that
/// branching in one obvious place.
class EmailOtpPage extends HookWidget {
  const EmailOtpPage({
    required this.email,
    required this.intent,
    required this.onAuthenticated,
    required this.onOnboarding,
    super.key,
    this.onChangeEmail,
  });

  final String email;
  final AuthFlowIntent intent;
  final VoidCallback onAuthenticated;
  final void Function(String email, String onboardingToken) onOnboarding;

  /// Back / "change email" action. Defaults to popping the OTP screen.
  final VoidCallback? onChangeEmail;

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController();
    final secondsLeft = useState(0);
    final canResend = useState(false);
    final isVerifying = useState(false);
    final colors = context.appColors;
    final typography = context.appTypography;

    useEffect(() {
      // Server-driven cooldown (replaces the old hardcoded 60s timer).
      context.read<AuthBloc>().add(AuthResendInfoRequestedEvent(email));
      return null;
    }, [email]);

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
      final code = controller.text.trim();

      switch (intent) {
        case AuthFlowIntent.createAccount:
          final result = await sl<VerifySignupOtpUseCase>()
              .call(VerifyEmailOtpParams(email: email, otp: code))
              .run();
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
        case AuthFlowIntent.signIn:
          final result = await sl<VerifyLoginOtpUseCase>()
              .call(VerifyEmailOtpParams(email: email, otp: code))
              .run();
          if (!context.mounted) return;
          await result.match(
            (failure) async {
              isVerifying.value = false;
              showAppErrorSnackbar(
                context: context,
                title: failure.localizedMessage(),
              );
            },
            (loginResult) => _handleLoginResult(
              context: context,
              email: email,
              loginResult: loginResult,
              isVerifying: isVerifying,
              onAuthenticated: onAuthenticated,
              onOnboarding: onOnboarding,
            ),
          );
      }
    }

    void resend() {
      if (!canResend.value) return;
      canResend.value = false;
      controller.clear();
      context.read<AuthBloc>().add(AuthResendOtpEvent(email));
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
          case AuthResendInfoState(:final resendInfo):
            secondsLeft.value = resendInfo.remainingSeconds;
            canResend.value = resendInfo.canResend;
          case AuthResendInfoFailureState():
            // Best-effort: fall back to allowing resend rather than
            // stranding the user behind a cooldown the server never
            // confirmed.
            canResend.value = true;
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
                      text: 'common.change'.tr(),
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
                  // Verification is intentionally NOT auto-triggered on
                  // completion (SAN-539). Re-editing a single digit of an
                  // already-full code would otherwise re-fire the verify call
                  // on every keystroke, burning OTP attempts and risking the
                  // rate limit. The user must explicitly tap "Verify".
                  onSubmitted: (_) => submit(),
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
                        text: 'common.resend'.tr(),
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

  /// Branches on `LoginResponseDto.status` for the OTP sign-in path. ACTIVE
  /// requires a follow-up `GET /me` (see [completeActiveLogin]) since
  /// `LoginResponseDto` carries only tokens; INCOMPLETE hands off to
  /// onboarding with the email already known (unlike the Google flow); the
  /// account being SUSPENDED sends the user to the dedicated route.
  static Future<void> _handleLoginResult({
    required BuildContext context,
    required String email,
    required LoginResult loginResult,
    required ValueNotifier<bool> isVerifying,
    required VoidCallback onAuthenticated,
    required void Function(String email, String onboardingToken) onOnboarding,
  }) async {
    switch (loginResult.status) {
      case AuthAccountStatus.active:
        final accessToken = loginResult.accessToken;
        final refreshToken = loginResult.refreshToken;
        if (accessToken == null || refreshToken == null) {
          isVerifying.value = false;
          if (context.mounted) {
            showAppErrorSnackbar(
              context: context,
              title: 'auth.malformed_login_response'.tr(),
            );
          }
          return;
        }
        final userResult = await completeActiveLogin(
          accessToken: accessToken,
          refreshToken: refreshToken,
          getCurrentUser: sl<GetCurrentUserUseCase>(),
          sessionManager: sl<SessionManager>(),
        ).run();
        isVerifying.value = false;
        if (!context.mounted) return;
        userResult.match(
          (failure) => showAppErrorSnackbar(
            context: context,
            title: failure.localizedMessage(),
          ),
          (_) => onAuthenticated(),
        );
      case AuthAccountStatus.incomplete:
        isVerifying.value = false;
        final onboardingToken = loginResult.accessToken;
        if (onboardingToken == null) {
          if (context.mounted) {
            showAppErrorSnackbar(
              context: context,
              title: 'auth.malformed_login_response'.tr(),
            );
          }
          return;
        }
        onOnboarding(email, onboardingToken);
      case AuthAccountStatus.suspended:
        isVerifying.value = false;
        if (context.mounted) context.go(AuthRoutes.suspended);
      case AuthAccountStatus.scheduledForDeletion:
        isVerifying.value = false;
        if (context.mounted) context.go(AuthRoutes.scheduledForDeletion);
    }
  }
}
