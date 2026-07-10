import 'package:auth/src/domain/entities/login_response_entity.dart';
import 'package:auth/src/domain/entities/user_entity.dart';
import 'package:auth/src/domain/usecases/usecase_params.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

abstract class AuthRepository {
  TaskEither<Failure, LoginResponseEntity> login(LoginParams params);
  TaskEither<Failure, void> logout();
  TaskEither<Failure, void> register(RegisterParams params);
  TaskEither<Failure, UserEntity?> checkSignInStatus();
  TaskEither<Failure, LoginResponseEntity> validateOtp(
    ValidateOtpParams params,
  );
  TaskEither<Failure, void> requestForgotPassword(
    ForgotPasswordRequestParams params,
  );
  TaskEither<Failure, void> verifyForgotPasswordOtp(
    VerifyForgotPasswordOtpParams params,
  );
  TaskEither<Failure, void> resetPassword(ResetPasswordParams params);
  TaskEither<Failure, void> resendOtp(ResendOtpParams params);
  TaskEither<Failure, void> deleteAccount(DeleteAccountParams params);
}
