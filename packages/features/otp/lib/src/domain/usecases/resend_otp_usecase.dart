import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:otp/src/domain/repositories/otp_repository.dart';
import 'package:otp/src/domain/usecases/otp_params.dart';

class ResendOtpUseCase implements UseCase<void, ResendOtpParams> {
  const ResendOtpUseCase(this._repository);

  final OtpRepository _repository;

  @override
  TaskEither<Failure, void> call(ResendOtpParams params) =>
      _repository.resendOtp(params);
}
