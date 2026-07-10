import 'package:auth/src/domain/entities/login_response_entity.dart';
import 'package:auth/src/domain/repositories/auth_repository.dart';
import 'package:auth/src/domain/usecases/usecase_params.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

class AuthLoginUseCase implements UseCase<LoginResponseEntity, LoginParams> {
  const AuthLoginUseCase(this._repository);

  final AuthRepository _repository;

  @override
  TaskEither<Failure, LoginResponseEntity> call(LoginParams params) =>
      _repository.login(params);
}
