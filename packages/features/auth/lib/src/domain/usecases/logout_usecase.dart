import 'package:auth/src/domain/repositories/auth_repository.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

class AuthLogoutUseCase implements UseCase<void, NoParams> {
  const AuthLogoutUseCase(this._repository);

  final AuthRepository _repository;

  @override
  TaskEither<Failure, void> call(NoParams params) => _repository.logout();
}
