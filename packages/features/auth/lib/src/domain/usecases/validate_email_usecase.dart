import 'package:auth/src/domain/repositories/auth_repository.dart';
import 'package:auth/src/domain/usecases/usecase_params.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

class ValidateEmailUseCase implements UseCase<bool, ValidateEmailParams> {
  const ValidateEmailUseCase(this._repository);

  final AuthRepository _repository;

  @override
  TaskEither<Failure, bool> call(ValidateEmailParams params) =>
      _repository.validateEmail(params);
}
