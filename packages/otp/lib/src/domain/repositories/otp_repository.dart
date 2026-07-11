import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:otp/src/domain/usecases/otp_params.dart';

abstract class OtpRepository {
  TaskEither<Failure, LoginResponseEntity> validateOtp(ValidateOtpParams params);

  TaskEither<Failure, void> resendOtp(ResendOtpParams params);
}
