import 'package:auth/src/domain/entities/auth_response_entity.dart';
import 'package:auth/src/domain/repositories/auth_repository.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

/// `POST /auth/social/signup` — register via Google/Apple.
class SocialSignupUseCase implements UseCase<AuthResponseEntity, NoParams> {
  const SocialSignupUseCase(this._repository);

  final AuthRepository _repository;

  @override
  TaskEither<Failure, AuthResponseEntity> call(NoParams params) =>
      _repository.socialSignup();
}
