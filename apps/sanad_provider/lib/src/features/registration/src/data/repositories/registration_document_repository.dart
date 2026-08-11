import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:document_flow/document_flow.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';
import 'package:sanad_provider/src/features/registration/src/data/datasources/media_remote_datasource.dart';
import 'package:sanad_provider/src/features/registration/src/data/models/profile_completion_request.dart';
import 'package:sanad_provider/src/features/registration/src/domain/provider_type/provider_type_spec.dart';

/// Registration's [DocumentFlowRepository] implementation.
///
/// Backs the shared upload/extract/submit pipeline with the onboarding
/// endpoints (`media/onboarding`, `auth/extract`, and the provider-type
/// specific profile-completion path). All onboarding-only concerns —
/// the short-lived Bearer token, provider type, and entered names — are read
/// from [DocumentFlowContext] (seeded by `RegistrationDetailsCubit`), so the
/// shared package never needs to know about any of them.
class RegistrationDocumentRepository implements DocumentFlowRepository {
  RegistrationDocumentRepository(
    this._remote,
    this._networkGuard,
    this._sessionManager,
  );

  final MediaRemoteDataSource _remote;
  final NetworkGuard _networkGuard;
  final SessionManager _sessionManager;

  @override
  TaskEither<Failure, DocumentMedia> uploadMedia(UploadMediaParams params) {
    final token = params.context.get<String>('onboardingToken');
    if (token == null || token.isEmpty) {
      return TaskEither.left(
        const UnauthorizedFailure(message: 'errors.unauthorized'),
      );
    }
    return _networkGuard.execute(
      action: _remote
          .uploadSingle(
            filePath: params.filePath,
            fileName: params.fileName,
            mimeType: params.mimeType,
            authorizationToken: token,
            uploadKey: params.uploadKey,
            onProgress: params.onProgress,
          )
          .map((response) => response.toEntity(type: params.type)),
    );
  }

  @override
  void cancelUpload(String uploadKey) => _remote.cancelUpload(uploadKey);

  @override
  TaskEither<Failure, ExtractedDocuments> extract(ExtractParams params) {
    final token = params.context.get<String>('onboardingToken');
    final frontId = params.uploadedIds[DocumentType.emiratesIdFront];
    final backId = params.uploadedIds[DocumentType.emiratesIdBack];
    if (token == null || frontId == null || backId == null) {
      return TaskEither.left(
        const ValidationFailure(message: 'errors.required_fields_missing'),
      );
    }
    return _networkGuard.execute(
      action: _remote.extractDocuments(
        authorizationToken: token,
        emiratesIdFrontId: frontId,
        emiratesIdBackId: backId,
        tradeLicenseId: params.uploadedIds[DocumentType.tradeLicense],
      ),
    );
  }

  @override
  TaskEither<Failure, Unit> submit(SubmitParams params) {
    final token = params.context.get<String>('onboardingToken');
    final frontId = params.uploadedIds[DocumentType.emiratesIdFront];
    final backId = params.uploadedIds[DocumentType.emiratesIdBack];
    final providerType = params.context.get<ProviderTypeSpec>('providerType');

    if (token == null ||
        frontId == null ||
        backId == null ||
        providerType == null) {
      return TaskEither.left(
        const ValidationFailure(message: 'errors.required_fields_missing'),
      );
    }

    final isOrganization = providerType.requiresTradeLicence;
    final extracted = params.extracted;
    final idRaw =
        extracted?.sectionOf(DocumentType.emiratesIdFront)?.raw ?? const {};
    final tlRaw =
        extracted?.sectionOf(DocumentType.tradeLicense)?.raw ?? const {};

    final contextFullName = params.context.get<String>('fullName') ?? '';
    final fullName = contextFullName.isNotEmpty
        ? contextFullName
        : (idRaw['fullNameEn'] ?? '');

    final contextBusinessName =
        params.context.get<String>('businessName') ?? '';
    final businessName = contextBusinessName.isNotEmpty
        ? contextBusinessName
        : (tlRaw['tradeNameEn'] ?? '');

    final request = ProfileCompletionRequest(
      emiratesIdFrontId: frontId,
      emiratesIdBackId: backId,
      userType: providerType.userType,
      tradeLicenseId: isOrganization
          ? params.uploadedIds[DocumentType.tradeLicense]
          : null,
      fullName: isOrganization ? null : (fullName.isNotEmpty ? fullName : null),
      businessName: isOrganization
          ? (businessName.isNotEmpty ? businessName : null)
          : null,
      representativeFullName: isOrganization
          ? (params.context.get<String>('representativeName') ?? '')
          : null,
    );

    return _networkGuard
        .execute(
          action: _remote.completeProfile(
            authorizationToken: token,
            request: request,
          ),
        )
        .flatMap(
          (authResult) => TaskEither.tryCatch(
            () async {
              await _sessionManager.save(authResult);
              return unit;
            },
            (error, _) => ErrorMapper.mapError(error),
          ),
        );
  }

  @override
  TaskEither<Failure, ExtractedDocuments> fetch(FetchParams params) =>
      TaskEither.right(const ExtractedDocuments());
}
