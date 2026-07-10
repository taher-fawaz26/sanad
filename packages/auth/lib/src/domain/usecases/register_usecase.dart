import 'package:auth/src/domain/repositories/auth_repository.dart';
import 'package:auth/src/domain/usecases/usecase_params.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

class AuthRegisterUseCase implements UseCase<void, RegisterParams> {
  const AuthRegisterUseCase(this._repository);

  final AuthRepository _repository;

  @override
  TaskEither<Failure, void> call(RegisterParams params) =>
      _repository.register(params);
}
