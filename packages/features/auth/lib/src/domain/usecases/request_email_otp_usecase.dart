import 'package:auth/src/domain/repositories/auth_repository.dart';
import 'package:auth/src/domain/usecases/usecase_params.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

class RequestEmailOtpUseCase implements UseCase<void, RequestEmailOtpParams> {
  const RequestEmailOtpUseCase(this._repository);

  final AuthRepository _repository;

  @override
  TaskEither<Failure, void> call(RequestEmailOtpParams params) =>
      _repository.requestEmailOtp(params);
}
