import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:organization_settings/src/domain/repositories/organization_contact_repository.dart';

class RequestPhoneOtpParams extends Equatable {
  const RequestPhoneOtpParams({required this.phone});

  final String phone;

  @override
  List<Object?> get props => [phone];
}

class RequestPhoneOtpUseCase
    implements UseCase<Unit, RequestPhoneOtpParams> {
  const RequestPhoneOtpUseCase(this._repository);

  final OrganizationContactRepository _repository;

  @override
  TaskEither<Failure, Unit> call(RequestPhoneOtpParams params) =>
      _repository.requestPhoneOtp(phone: params.phone);
}
