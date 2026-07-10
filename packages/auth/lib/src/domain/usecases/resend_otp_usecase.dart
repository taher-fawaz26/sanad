import 'package:auth/src/domain/repositories/auth_repository.dart';
import 'package:auth/src/domain/usecases/usecase_params.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

class ResendOtpUseCase implements UseCase<void, ResendOtpParams> {
  const ResendOtpUseCase(this._repository);

  final AuthRepository _repository;

  @override
  TaskEither<Failure, void> call(ResendOtpParams params) =>
      _repository.resendOtp(params);
}
