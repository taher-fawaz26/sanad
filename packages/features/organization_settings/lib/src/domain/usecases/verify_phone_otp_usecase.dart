import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:organization_settings/src/domain/repositories/organization_contact_repository.dart';

class VerifyPhoneOtpParams extends Equatable {
  const VerifyPhoneOtpParams({required this.phone, required this.otp});

  final String phone;
  final String otp;

  @override
  List<Object?> get props => [phone, otp];
}

class VerifyPhoneOtpUseCase implements UseCase<Unit, VerifyPhoneOtpParams> {
  const VerifyPhoneOtpUseCase(this._repository);

  final OrganizationContactRepository _repository;

  @override
  TaskEither<Failure, Unit> call(VerifyPhoneOtpParams params) =>
      _repository.verifyPhoneOtp(phone: params.phone, otp: params.otp);
}
