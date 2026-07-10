import 'package:auth/src/domain/repositories/auth_repository.dart';
import 'package:auth/src/domain/usecases/usecase_params.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

class RequestForgotPasswordUseCase
    implements UseCase<void, ForgotPasswordRequestParams> {
  const RequestForgotPasswordUseCase(this._repository);

  final AuthRepository _repository;

  @override
  TaskEither<Failure, void> call(ForgotPasswordRequestParams params) =>
      _repository.requestForgotPassword(params);
}
