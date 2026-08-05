import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';
import 'package:organization_settings/src/data/datasources/organization_contact_remote_datasource.dart';
import 'package:organization_settings/src/data/models/requests/contact_email_request.dart';
import 'package:organization_settings/src/data/models/requests/contact_phone_request.dart';
import 'package:organization_settings/src/data/models/requests/verify_email_request.dart';
import 'package:organization_settings/src/data/models/requests/verify_phone_request.dart';
import 'package:organization_settings/src/domain/entities/organization_contact_entity.dart';
import 'package:organization_settings/src/domain/repositories/organization_contact_repository.dart';

class OrganizationContactRepositoryImpl
    implements OrganizationContactRepository {
  const OrganizationContactRepositoryImpl(this._remote, this._networkGuard);

  final OrganizationContactRemoteDataSource _remote;
  final NetworkGuard _networkGuard;

  @override
  TaskEither<Failure, OrganizationContactEntity> getContact() =>
      _networkGuard.execute(
        action: _remote.getContact().map((response) => response.toEntity()),
      );

  @override
  TaskEither<Failure, Unit> requestPhoneOtp({required String phone}) =>
      _networkGuard.execute(
        action: _remote.requestPhoneOtp(ContactPhoneRequest(phone: phone)),
      );

  @override
  TaskEither<Failure, Unit> verifyPhoneOtp({
    required String phone,
    required String otp,
  }) => _networkGuard.execute(
    action: _remote.verifyPhoneOtp(VerifyPhoneRequest(phone: phone, otp: otp)),
  );

  @override
  TaskEither<Failure, Unit> requestEmailOtp({required String email}) =>
      _networkGuard.execute(
        action: _remote.requestEmailOtp(ContactEmailRequest(email: email)),
      );

  @override
  TaskEither<Failure, Unit> verifyEmailOtp({
    required String email,
    required String otp,
  }) => _networkGuard.execute(
    action: _remote.verifyEmailOtp(VerifyEmailRequest(email: email, otp: otp)),
  );
}
