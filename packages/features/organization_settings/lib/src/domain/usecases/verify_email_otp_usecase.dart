import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:organization_settings/src/domain/repositories/organization_contact_repository.dart';

class VerifyEmailOtpParams extends Equatable {
  const VerifyEmailOtpParams({required this.email, required this.otp});

  final String email;
  final String otp;

  @override
  List<Object?> get props => [email, otp];
}

class VerifyEmailOtpUseCase implements UseCase<Unit, VerifyEmailOtpParams> {
  const VerifyEmailOtpUseCase(this._repository);

  final OrganizationContactRepository _repository;

  @override
  TaskEither<Failure, Unit> call(VerifyEmailOtpParams params) =>
      _repository.verifyEmailOtp(email: params.email, otp: params.otp);
}
