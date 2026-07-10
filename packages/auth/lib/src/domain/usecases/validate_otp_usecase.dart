import 'package:auth/src/domain/entities/login_response_entity.dart';
import 'package:auth/src/domain/repositories/auth_repository.dart';
import 'package:auth/src/domain/usecases/usecase_params.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

class AuthValidateOtpUseCase
    implements UseCase<LoginResponseEntity, ValidateOtpParams> {
  const AuthValidateOtpUseCase(this._repository);

  final AuthRepository _repository;

  @override
  TaskEither<Failure, LoginResponseEntity> call(ValidateOtpParams params) =>
      _repository.validateOtp(params);
}
