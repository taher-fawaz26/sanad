import 'dart:async';

import 'package:auth/src/domain/entities/auth_response_entity.dart';
import 'package:auth/src/domain/entities/login_result_entity.dart';
import 'package:auth/src/domain/enums/auth_account_status.dart';
import 'package:auth/src/domain/enums/auth_flow_intent.dart';
import 'package:auth/src/domain/usecases/get_current_user_usecase.dart';
import 'package:auth/src/domain/usecases/get_resend_info_usecase.dart';
import 'package:auth/src/domain/usecases/request_login_otp_usecase.dart';
import 'package:auth/src/domain/usecases/request_signup_otp_usecase.dart';
import 'package:auth/src/domain/usecases/resend_otp_usecase.dart';
import 'package:auth/src/domain/usecases/verify_login_otp_usecase.dart';
import 'package:auth/src/domain/usecases/verify_signup_otp_usecase.dart';
import 'package:auth/src/domain/verifiers/auth_otp_verifiers.dart';
import 'package:auth/src/routes/auth_routes.dart';
import 'package:auth/src/session/complete_active_login.dart';
import 'package:auth/src/session/session_manager.dart';
import 'package:core/core.dart' show sl;
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
import 'package:otp/otp.dart';
import 'package:shared_ui/shared_ui.dart';

/// Shared passwordless OTP screen (Figma `sign in` / OTP, `3026:19710`).
///
/// Reached identically from Sign In and Sign Up, disambiguated by [intent].
/// The screen itself is the shared `otp` package's `OtpView` — this widget
/// contributes only the intent-specific verifier and what to do with the
/// result. The two verify endpoints return different shapes
/// (`AuthResponseEntity` vs `LoginResult`), which is why there are two typed
/// verifiers rather than one generic one.
class EmailOtpPage extends StatefulWidget {
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
  State<EmailOtpPage> createState() => _EmailOtpPageState();
}

class _EmailOtpPageState extends State<EmailOtpPage> {
  void _changeEmail() {
    if (widget.onChangeEmail != null) {
      widget.onChangeEmail!();
    } else if (context.canPop()) {
      context.pop();
    }
  }

  OtpFlowConfig<T> _config<T>(OtpVerifier<T> verifier) =>
      OtpFlowConfig<T>.email(
        destination: widget.email,
        verifier: verifier,
        purpose: OtpPurpose.login,
        // Verification is intentionally NOT auto-triggered on completion
        // (SAN-539). Re-editing a digit of an already-full code would
        // otherwise re-fire the verify call, burning OTP attempts and risking
        // the rate limit. The user must explicitly tap "Verify".
        autoSubmit: false,
        // Auth owns its own success routing; a confirmation screen here would
        // sit between the user and the app they just signed in to.
        showSuccessScreen: false,
        onChangeDestination: (_) async {
          _changeEmail();
          return null;
        },
      );

  void _handleSignupResult(OtpResult<AuthResponseEntity> result) {
    if (result case OtpVerified<AuthResponseEntity>(:final data)) {
      switch (data) {
        case AuthSessionEntity():
          widget.onAuthenticated();
        case OnboardingAuthEntity(:final onboardingToken, :final user):
          widget.onOnboarding(user.email, onboardingToken);
      }
      return;
    }
    _reportAndLeave(result);
  }

  /// Branches on `LoginResponseDto.status`. ACTIVE requires a follow-up
  /// `GET /me` (see [completeActiveLogin]) since `LoginResponseDto` carries
  /// only tokens; INCOMPLETE hands off to onboarding with the email already
  /// known (unlike the Google flow); SUSPENDED and SCHEDULED_FOR_DELETION go
  /// to their dedicated routes.
  Future<void> _handleLoginResult(OtpResult<LoginResult> result) async {
    if (result case OtpVerified<LoginResult>(data: final loginResult)) {
      switch (loginResult.status) {
        case AuthAccountStatus.active:
          final accessToken = loginResult.accessToken;
          final refreshToken = loginResult.refreshToken;
          if (accessToken == null || refreshToken == null) {
            _showMalformed();
            return;
          }
          final userResult = await completeActiveLogin(
            accessToken: accessToken,
            refreshToken: refreshToken,
            getCurrentUser: sl<GetCurrentUserUseCase>(),
            sessionManager: sl<SessionManager>(),
          ).run();
          if (!mounted) return;
          userResult.match(
            (failure) => showAppErrorSnackbar(
              context: context,
              title: failure.localizedMessage(),
            ),
            (_) => widget.onAuthenticated(),
          );
        case AuthAccountStatus.incomplete:
          final onboardingToken = loginResult.accessToken;
          if (onboardingToken == null) {
            _showMalformed();
            return;
          }
          widget.onOnboarding(widget.email, onboardingToken);
        case AuthAccountStatus.suspended:
          context.go(AuthRoutes.suspended);
        case AuthAccountStatus.scheduledForDeletion:
          context.go(AuthRoutes.scheduledForDeletion);
      }
      return;
    }
    _reportAndLeave(result);
  }

  void _showMalformed() {
    if (!mounted) return;
    showAppErrorSnackbar(
      context: context,
      title: 'auth.malformed_login_response'.tr(),
    );
  }

  /// A dismissal returns the user to the email step; a hard failure says why
  /// first. Either way this screen has nothing left to show.
  void _reportAndLeave(OtpResult<Object?> result) {
    if (result case OtpFailed(:final failure)) {
      showAppErrorSnackbar(
        context: context,
        title: failure.localizedMessage(),
      );
    }
    _changeEmail();
  }

  @override
  Widget build(BuildContext context) {
    // Hosted inline rather than pushed: this IS the auth OTP screen, so it
    // keeps the auth chrome instead of stacking a second route on top of a
    // blank one.
    return AuthScreenShell(
      onBack: _changeEmail,
      title: 'auth.otp_title'.tr(),
      child: switch (widget.intent) {
        AuthFlowIntent.createAccount => OtpHost<AuthResponseEntity>(
          config: _config<AuthResponseEntity>(
            SignupOtpVerifier(
              email: widget.email,
              requestOtp: sl<RequestSignupOtpUseCase>(),
              verifyOtp: sl<VerifySignupOtpUseCase>(),
              resendOtp: sl<ResendOtpUseCase>(),
              getResendInfo: sl<GetResendInfoUseCase>(),
            ),
          ),
          onResult: _handleSignupResult,
        ),
        AuthFlowIntent.signIn => OtpHost<LoginResult>(
          config: _config<LoginResult>(
            LoginOtpVerifier(
              email: widget.email,
              requestOtp: sl<RequestLoginOtpUseCase>(),
              verifyOtp: sl<VerifyLoginOtpUseCase>(),
              resendOtp: sl<ResendOtpUseCase>(),
              getResendInfo: sl<GetResendInfoUseCase>(),
            ),
          ),
          onResult: (result) => unawaited(_handleLoginResult(result)),
        ),
      },
    );
  }
}
