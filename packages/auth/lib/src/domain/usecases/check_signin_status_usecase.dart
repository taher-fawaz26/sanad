import 'package:auth/src/domain/entities/user_entity.dart';
import 'package:auth/src/domain/repositories/auth_repository.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

class AuthCheckSignInStatusUseCase implements UseCase<UserEntity?, NoParams> {
  const AuthCheckSignInStatusUseCase(this._repository);

  final AuthRepository _repository;

  @override
  TaskEither<Failure, UserEntity?> call(NoParams params) =>
      _repository.checkSignInStatus();
}
