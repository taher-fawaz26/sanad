import 'package:auth/src/domain/entities/login_result_entity.dart';
import 'package:auth/src/domain/repositories/auth_repository.dart';
import 'package:auth/src/domain/usecases/usecase_params.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

/// Step 2 sign-in — `POST /auth/login/verify`.
class VerifyLoginOtpUseCase
    implements UseCase<LoginResult, VerifyEmailOtpParams> {
  const VerifyLoginOtpUseCase(this._repository);

  final AuthRepository _repository;

  @override
  TaskEither<Failure, LoginResult> call(VerifyEmailOtpParams params) =>
      _repository.verifyLoginOtp(params);
}
