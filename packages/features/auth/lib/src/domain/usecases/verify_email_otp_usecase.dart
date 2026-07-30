import 'package:auth/src/domain/entities/email_auth_result.dart';
import 'package:auth/src/domain/repositories/auth_repository.dart';
import 'package:auth/src/domain/usecases/usecase_params.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

class VerifyEmailOtpUseCase
    implements UseCase<EmailAuthResult, VerifyEmailOtpParams> {
  const VerifyEmailOtpUseCase(this._repository);

  final AuthRepository _repository;

  @override
  TaskEither<Failure, EmailAuthResult> call(VerifyEmailOtpParams params) =>
      _repository.verifyEmailOtp(params);
}
