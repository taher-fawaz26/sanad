import 'package:auth/src/domain/entities/auth_identity_entity.dart';
import 'package:auth/src/domain/repositories/auth_repository.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

/// `GET /me` — canonical identity for every persona.
class GetCurrentUserUseCase implements UseCase<AuthIdentity, NoParams> {
  const GetCurrentUserUseCase(this._repository);

  final AuthRepository _repository;

  @override
  TaskEither<Failure, AuthIdentity> call(NoParams params) =>
      _repository.getCurrentUser();
}
