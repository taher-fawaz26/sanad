import 'package:core/core.dart';
import 'package:forgot_password/src/domain/repositories/forgot_password_repository.dart';
import 'package:forgot_password/src/domain/usecases/forgot_password_params.dart';
import 'package:fpdart/fpdart.dart';

class ResetPasswordUseCase implements UseCase<void, ResetPasswordParams> {
  const ResetPasswordUseCase(this._repository);

  final ForgotPasswordRepository _repository;

  @override
  TaskEither<Failure, void> call(ResetPasswordParams params) =>
      _repository.resetPassword(params);
}
