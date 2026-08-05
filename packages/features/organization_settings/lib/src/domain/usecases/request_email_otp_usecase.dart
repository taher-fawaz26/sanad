import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:organization_settings/src/domain/repositories/organization_contact_repository.dart';

class RequestEmailOtpParams extends Equatable {
  const RequestEmailOtpParams({required this.email});

  final String email;

  @override
  List<Object?> get props => [email];
}

class RequestEmailOtpUseCase
    implements UseCase<Unit, RequestEmailOtpParams> {
  const RequestEmailOtpUseCase(this._repository);

  final OrganizationContactRepository _repository;

  @override
  TaskEither<Failure, Unit> call(RequestEmailOtpParams params) =>
      _repository.requestEmailOtp(email: params.email);
}
