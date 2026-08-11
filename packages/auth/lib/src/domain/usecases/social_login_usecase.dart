import 'package:auth/src/domain/entities/login_result_entity.dart';
import 'package:auth/src/domain/repositories/auth_repository.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

/// `POST /auth/social/login` — sign in via Google/Apple.
class SocialLoginUseCase implements UseCase<LoginResult, NoParams> {
  const SocialLoginUseCase(this._repository);

  final AuthRepository _repository;

  @override
  TaskEither<Failure, LoginResult> call(NoParams params) =>
      _repository.socialLogin();
}
