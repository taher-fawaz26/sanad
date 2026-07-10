import 'package:auth/src/domain/repositories/auth_repository.dart';
import 'package:auth/src/domain/usecases/usecase_params.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

class VerifyForgotPasswordOtpUseCase
    implements UseCase<void, VerifyForgotPasswordOtpParams> {
  const VerifyForgotPasswordOtpUseCase(this._repository);

  final AuthRepository _repository;

  @override
  TaskEither<Failure, void> call(VerifyForgotPasswordOtpParams params) =>
      _repository.verifyForgotPasswordOtp(params);
}
