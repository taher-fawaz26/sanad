import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';
import 'package:organization_settings/src/data/endpoints/organization_contact_api_paths.dart';
import 'package:organization_settings/src/data/models/organization_contact_response.dart';
import 'package:organization_settings/src/data/models/requests/contact_email_request.dart';
import 'package:organization_settings/src/data/models/requests/contact_phone_request.dart';
import 'package:organization_settings/src/data/models/requests/verify_email_request.dart';
import 'package:organization_settings/src/data/models/requests/verify_phone_request.dart';

/// Remote data source for organization contact info (phone/email) —
/// request/verify OTP and fetch the current verified values.
abstract interface class OrganizationContactRemoteDataSource {
  TaskEither<Failure, OrganizationContactResponse> getContact();

  TaskEither<Failure, Unit> requestPhoneOtp(ContactPhoneRequest model);

  TaskEither<Failure, Unit> verifyPhoneOtp(VerifyPhoneRequest model);

  TaskEither<Failure, Unit> requestEmailOtp(ContactEmailRequest model);

  TaskEither<Failure, Unit> verifyEmailOtp(VerifyEmailRequest model);
}

class OrganizationContactRemoteDataSourceImpl
    implements OrganizationContactRemoteDataSource {
  const OrganizationContactRemoteDataSourceImpl(this._apiClient);

  final BaseApiClient _apiClient;

  @override
  TaskEither<Failure, OrganizationContactResponse> getContact() =>
      _apiClient.request<OrganizationContactResponse>(
        path: OrganizationContactApiPaths.contact,
        method: RequestMethod.get,
        parser: (data) => OrganizationContactResponse.fromJson(
          data as Map<String, dynamic>,
        ),
      );

  @override
  TaskEither<Failure, Unit> requestPhoneOtp(ContactPhoneRequest model) =>
      _apiClient.request<Unit>(
        path: OrganizationContactApiPaths.phoneRequestOtp,
        method: RequestMethod.post,
        body: model.toMap(),
        parser: (_) => unit,
      );

  @override
  TaskEither<Failure, Unit> verifyPhoneOtp(VerifyPhoneRequest model) =>
      _apiClient.request<Unit>(
        path: OrganizationContactApiPaths.phoneVerify,
        method: RequestMethod.post,
        body: model.toMap(),
        parser: (_) => unit,
      );

  @override
  TaskEither<Failure, Unit> requestEmailOtp(ContactEmailRequest model) =>
      _apiClient.request<Unit>(
        path: OrganizationContactApiPaths.emailRequestOtp,
        method: RequestMethod.post,
        body: model.toMap(),
        parser: (_) => unit,
      );

  @override
  TaskEither<Failure, Unit> verifyEmailOtp(VerifyEmailRequest model) =>
      _apiClient.request<Unit>(
        path: OrganizationContactApiPaths.emailVerify,
        method: RequestMethod.post,
        body: model.toMap(),
        parser: (_) => unit,
      );
}
