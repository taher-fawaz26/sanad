import 'package:auth/src/domain/entities/auth_response_entity.dart';
import 'package:auth/src/domain/entities/user_entity.dart';
import 'package:auth/src/domain/usecases/usecase_params.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

abstract class AuthRepository {
  /// Requests an email OTP for the passwordless sign-in / sign-up flow.
  TaskEither<Failure, void> requestEmailOtp(RequestEmailOtpParams params);

  /// Verifies the email OTP, resolving to an authenticated session or an
  /// onboarding hand-off.
  TaskEither<Failure, AuthResponseEntity> verifyEmailOtp(
    VerifyEmailOtpParams params,
  );

  TaskEither<Failure, AuthResponseEntity> signInWithGoogle();
  TaskEither<Failure, void> logout();
  TaskEither<Failure, UserEntity?> checkSignInStatus();
  TaskEither<Failure, void> deleteAccount(DeleteAccountParams params);
  TaskEither<Failure, bool> validateEmail(ValidateEmailParams params);
}
