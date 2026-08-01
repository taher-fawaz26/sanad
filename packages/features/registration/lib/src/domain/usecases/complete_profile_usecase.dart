import 'package:auth/auth.dart' show AuthSessionEntity;
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:registration/src/data/models/profile_completion_request.dart';
import 'package:registration/src/domain/repositories/media_repository.dart';

/// Parameters for completing provider profile.
class CompleteProfileParams {
  const CompleteProfileParams({
    required this.authorizationToken,
    required this.emiratesIdFrontId,
    required this.emiratesIdBackId,
    required this.isOrganization,
    this.tradeLicenseId,
    this.fullName,
    this.businessName,
    this.representativeFullName,
    this.representativeEmail,
  });

  final String authorizationToken;
  final String emiratesIdFrontId;
  final String emiratesIdBackId;
  final bool isOrganization;

  // Individual provider fields.
  final String? fullName;

  // Company provider fields.
  final String? tradeLicenseId;
  final String? businessName;
  final String? representativeFullName;
  final String? representativeEmail;
}

/// Completes the provider profile by posting to either the individual or
/// company endpoint based on account type.
class CompleteProfileUseCase
    extends UseCase<AuthSessionEntity, CompleteProfileParams> {
  CompleteProfileUseCase(this._repository);

  final MediaRepository _repository;

  @override
  TaskEither<Failure, AuthSessionEntity> call(CompleteProfileParams params) {
    final request = ProfileCompletionRequest(
      emiratesIdFrontId: params.emiratesIdFrontId,
      emiratesIdBackId: params.emiratesIdBackId,
      tradeLicenseId: params.tradeLicenseId,
      fullName: params.fullName,
      businessName: params.businessName,
      representativeFullName: params.representativeFullName,
      representativeEmail: params.representativeEmail,
    );

    if (params.isOrganization) {
      return _repository.completeCompanyProfile(
        authorizationToken: params.authorizationToken,
        request: request,
      );
    } else {
      return _repository.completeIndividualProfile(
        authorizationToken: params.authorizationToken,
        request: request,
      );
    }
  }
}
