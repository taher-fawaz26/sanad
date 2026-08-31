import 'package:auth/src/domain/entities/auth_identity_entity.dart';
import 'package:auth/src/domain/entities/auth_response_entity.dart';
import 'package:auth/src/domain/entities/client_profile_entity.dart';
import 'package:auth/src/domain/entities/client_verify_result_entity.dart';
import 'package:auth/src/domain/entities/login_result_entity.dart';
import 'package:auth/src/domain/entities/resend_info_entity.dart';
import 'package:auth/src/domain/usecases/usecase_params.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

abstract class AuthRepository {
  /// Step 1 signup — requests a signup OTP.
  TaskEither<Failure, void> requestSignupOtp(RequestEmailOtpParams params);

  /// Step 2 signup — verifies the OTP, resolving to an onboarding hand-off.
  TaskEither<Failure, AuthResponseEntity> verifySignupOtp(
    VerifyEmailOtpParams params,
  );

  /// Step 1 sign-in — requests a login OTP.
  TaskEither<Failure, void> requestLoginOtp(RequestEmailOtpParams params);

  /// Step 2 sign-in — verifies the OTP, branching on account status.
  TaskEither<Failure, LoginResult> verifyLoginOtp(VerifyEmailOtpParams params);

  /// Resends the active OTP (single endpoint, not split by intent).
  TaskEither<Failure, void> resendOtp(RequestEmailOtpParams params);

  /// Server-driven resend cooldown for the given email.
  TaskEither<Failure, ResendInfo> getResendInfo(RequestEmailOtpParams params);

  /// Registers via Google, resolving to an onboarding hand-off.
  TaskEither<Failure, AuthResponseEntity> socialSignup();

  /// Signs in via Google, branching on account status.
  TaskEither<Failure, LoginResult> socialLogin();

  /// Canonical identity for every persona (`GET /me`).
  TaskEither<Failure, AuthIdentity> getCurrentUser();

  TaskEither<Failure, void> logout();

  // ── Unified client sign-in ─────────────────────────────────────────────

  /// Dispatch (or resend) a client OTP for `{method, value}`.
  TaskEither<Failure, void> requestClientOtp(ClientOtpParams params);

  /// Server-driven client resend cooldown for `{method, value}`.
  TaskEither<Failure, ResendInfo> getClientResendInfo(ClientOtpParams params);

  /// Verify a client OTP, resolving to a [ClientVerifyResult] to branch on.
  TaskEither<Failure, ClientVerifyResult> verifyClientOtp(
    VerifyClientOtpParams params,
  );

  /// Set the client display name / preferred language (`PATCH clients/me`).
  TaskEither<Failure, ClientProfile> updateClientProfile(
    UpdateClientProfileParams params,
  );
}
