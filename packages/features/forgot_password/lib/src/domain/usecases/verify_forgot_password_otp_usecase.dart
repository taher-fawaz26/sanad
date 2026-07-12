import 'package:core/core.dart';
import 'package:forgot_password/src/domain/repositories/forgot_password_repository.dart';
import 'package:forgot_password/src/domain/usecases/forgot_password_params.dart';
import 'package:fpdart/fpdart.dart';

class VerifyForgotPasswordOtpUseCase
    implements UseCase<void, VerifyForgotPasswordOtpParams> {
  const VerifyForgotPasswordOtpUseCase(this._repository);

  final ForgotPasswordRepository _repository;

  @override
  TaskEither<Failure, void> call(VerifyForgotPasswordOtpParams params) =>
      _repository.verifyForgotPasswordOtp(params);
}
