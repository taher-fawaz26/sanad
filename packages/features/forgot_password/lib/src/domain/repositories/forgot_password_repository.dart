import 'package:core/core.dart';
import 'package:forgot_password/src/domain/usecases/forgot_password_params.dart';
import 'package:fpdart/fpdart.dart';

abstract class ForgotPasswordRepository {
  TaskEither<Failure, void> requestForgotPassword(
    ForgotPasswordRequestParams params,
  );

  TaskEither<Failure, void> verifyForgotPasswordOtp(
    VerifyForgotPasswordOtpParams params,
  );

  TaskEither<Failure, void> resetPassword(ResetPasswordParams params);
}
