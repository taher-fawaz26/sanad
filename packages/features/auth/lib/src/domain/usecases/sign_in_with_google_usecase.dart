import 'package:auth/src/domain/entities/email_auth_result.dart';
import 'package:auth/src/domain/repositories/auth_repository.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

class SignInWithGoogleUseCase implements UseCase<EmailAuthResult, NoParams> {
  const SignInWithGoogleUseCase(this._repository);

  final AuthRepository _repository;

  @override
  TaskEither<Failure, EmailAuthResult> call(NoParams params) =>
      _repository.signInWithGoogle();
}
