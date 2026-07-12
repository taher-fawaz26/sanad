import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:otp/src/domain/repositories/otp_repository.dart';
import 'package:otp/src/domain/usecases/otp_params.dart';

class ValidateOtpUseCase
    implements UseCase<LoginResponseEntity, ValidateOtpParams> {
  const ValidateOtpUseCase(this._repository);

  final OtpRepository _repository;

  @override
  TaskEither<Failure, LoginResponseEntity> call(ValidateOtpParams params) =>
      _repository.validateOtp(params);
}
