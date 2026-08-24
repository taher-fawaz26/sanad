import 'package:core/core.dart';
import 'package:document_flow/document_flow.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/datasources/legal_data_remote_datasource.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/models/legal_data_response.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/models/national_id_extraction_response.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/models/trade_license_extraction_response.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/legal_data_status.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/personal_legal_data_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/trade_license_legal_data_entity.dart';

/// Organization Settings' [DocumentFlowRepository] implementation.
///
/// Backs the shared upload/extract/submit pipeline with the per-document
/// `service-provider/legal-data/{emirates-id,trade-license}` endpoints.
/// Unlike registration, this flow runs under an authenticated session —
/// [DocumentFlowContext] stays empty; the session token is attached
/// automatically by the network layer.
///
/// Renewal is scoped to exactly one document per flow instance
/// (`DocumentScope.requiredDocuments` only ever lists the Emirates ID pair
/// *or* the trade licence, never both — see `document_scope.dart`), so
/// [params.uploadedIds] alone tells [extract]/[submit] which document this
/// call concerns; no separate scope needs to be threaded through
/// [DocumentFlowContext].
class OrganizationDocumentRepository implements DocumentFlowRepository {
  OrganizationDocumentRepository(this._remote, this._networkGuard);

  final LegalDataRemoteDataSource _remote;
  final NetworkGuard _networkGuard;

  @override
  TaskEither<Failure, DocumentMedia> uploadMedia(UploadMediaParams params) =>
      _networkGuard.execute(
        action: _remote
            .uploadMedia(
              filePath: params.filePath,
              fileName: params.fileName,
              mimeType: params.mimeType,
              uploadKey: params.uploadKey,
              onProgress: params.onProgress,
            )
            .map(
              (response) => DocumentMedia(
                id: response.id,
                url: response.url,
                fileName: response.originalName,
                mimeType: response.mimeType,
                size: 0,
                type: params.type,
              ),
            ),
      );

  @override
  void cancelUpload(String uploadKey) => _remote.cancelUpload(uploadKey);

  @override
  TaskEither<Failure, ExtractedDocuments> extract(ExtractParams params) {
    final tradeLicenseId = params.uploadedIds[DocumentType.tradeLicense];
    if (tradeLicenseId != null) {
      return _networkGuard
          .execute(
            action: _remote.extractTradeLicense(tradeLicenseId: tradeLicenseId),
          )
          .map(_toTradeLicenseExtractedDocuments);
    }

    final frontId = params.uploadedIds[DocumentType.emiratesIdFront];
    final backId = params.uploadedIds[DocumentType.emiratesIdBack];
    if (frontId == null || backId == null) {
      return TaskEither.left(
        const ValidationFailure(message: 'errors.required_fields_missing'),
      );
    }
    return _networkGuard
        .execute(
          action: _remote.extractEmiratesId(
            emiratesIdFrontId: frontId,
            emiratesIdBackId: backId,
          ),
        )
        .map(_toEmiratesIdExtractedDocuments);
  }

  @override
  TaskEither<Failure, Unit> submit(SubmitParams params) {
    final tradeLicenseId = params.uploadedIds[DocumentType.tradeLicense];
    if (tradeLicenseId != null) {
      return _networkGuard.execute(
        action: _remote.confirmTradeLicense(tradeLicenseId: tradeLicenseId),
      );
    }

    final frontId = params.uploadedIds[DocumentType.emiratesIdFront];
    final backId = params.uploadedIds[DocumentType.emiratesIdBack];
    if (frontId == null || backId == null) {
      return TaskEither.left(
        const ValidationFailure(message: 'errors.required_fields_missing'),
      );
    }
    return _networkGuard.execute(
      action: _remote.confirmEmiratesId(
        emiratesIdFrontId: frontId,
        emiratesIdBackId: backId,
      ),
    );
  }

  @override
  TaskEither<Failure, ExtractedDocuments> fetch(FetchParams params) =>
      _networkGuard
          .execute(action: _remote.fetchLegalData())
          .map(_toExtractedDocuments);

  /// The prefetch/prefill read (`GET legal-data`) still returns both
  /// documents together — unlike extract/confirm, this endpoint was never
  /// split — so this stays a combined mapping used to seed both possible
  /// scopes' initial state.
  ExtractedDocuments _toExtractedDocuments(LegalDataResponse response) {
    final personal = response.personalLegalData?.toEntity();
    final tradeLicense = response.tradeLicenseLegalData?.toEntity();

    return ExtractedDocuments(
      sections: [
        _emiratesIdSection(personal),
        if (tradeLicense != null) _tradeLicenseSection(tradeLicense),
      ],
    );
  }

  ExtractedDocument _emiratesIdSection(PersonalLegalDataEntity? personal) {
    if (personal == null) {
      return const ExtractedDocument(
        type: DocumentType.emiratesIdFront,
        fields: [],
        issue: DocumentIssue.imageUnclear,
      );
    }
    return ExtractedDocument(
      type: DocumentType.emiratesIdFront,
      fields: const [],
      issue: personal.status == LegalDataStatus.expired
          ? DocumentIssue.expired
          : DocumentIssue.none,
      raw: {
        'fullNameEn': personal.fullNameEnglish ?? '',
        'fullNameAr': personal.fullNameArabic ?? '',
        'idNumber': personal.idNumber ?? '',
        'nationality': personal.nationality ?? '',
        'dateOfBirth': personal.dateOfBirth ?? '',
        'expiryDate': personal.expiryDate ?? '',
        'gender': personal.gender ?? '',
      },
      media: [
        if (personal.frontMedia case final front?)
          DocumentMediaRef(
            type: DocumentType.emiratesIdFront,
            mediaId: front.id,
            mediaUrl: front.url,
            fileName: front.originalName,
            mimeType: front.mimeType,
          ),
        if (personal.backMedia case final back?)
          DocumentMediaRef(
            type: DocumentType.emiratesIdBack,
            mediaId: back.id,
            mediaUrl: back.url,
            fileName: back.originalName,
            mimeType: back.mimeType,
          ),
      ],
    );
  }

  ExtractedDocument _tradeLicenseSection(
    TradeLicenseLegalDataEntity tradeLicense,
  ) => ExtractedDocument(
    type: DocumentType.tradeLicense,
    fields: const [],
    issue: tradeLicense.status == LegalDataStatus.expired
        ? DocumentIssue.expired
        : DocumentIssue.none,
    raw: {
      'tradeNameEn': tradeLicense.tradeNameEnglish ?? '',
      'tradeNameAr': tradeLicense.tradeNameArabic ?? '',
      'licenceNo': tradeLicense.licenseNumber ?? '',
      'licenceType': tradeLicense.licenseType ?? '',
      'establishmentDate': tradeLicense.establishmentDate ?? '',
      'issuanceDate': tradeLicense.issuanceDate ?? '',
      'legalForm': tradeLicense.legalForm ?? '',
      'unifiedRegNo': tradeLicense.unifiedRegistrationNumber ?? '',
      'unifiedLicenceNo': tradeLicense.unifiedLicenseNumber ?? '',
    },
    media: [
      if (tradeLicense.document case final document?)
        DocumentMediaRef(
          type: DocumentType.tradeLicense,
          mediaId: document.id,
          mediaUrl: document.url,
          fileName: document.originalName,
          mimeType: document.mimeType,
        ),
    ],
  );

  /// Maps a bare Emirates ID extraction preview (no envelope, no media, no
  /// `id`/timestamps — see [NationalIdExtractionResponse]) to a single-section
  /// result. [DocumentStatus]/[IdVerification] drive the blocking issue via
  /// the same [deriveDocumentIssue] onboarding uses, so the two flows agree
  /// on what counts as "needs action".
  ExtractedDocuments _toEmiratesIdExtractedDocuments(
    NationalIdExtractionResponse response,
  ) {
    final personal = response.toEntity();
    final status = _toDocumentStatus(personal.status);
    return ExtractedDocuments(
      sections: [
        ExtractedDocument(
          type: DocumentType.emiratesIdFront,
          fields: const [],
          status: status,
          missingFields: personal.missingFields,
          idVerification: personal.idVerification,
          issue: deriveDocumentIssue(
            status: status,
            missingFields: personal.missingFields,
            idVerification: personal.idVerification,
          ),
          repair:
              personal.idVerification != null &&
                  !personal.idVerification!.matched
              ? emiratesIdMismatchRepairTarget
              : null,
          raw: {
            'fullNameEn': personal.fullNameEnglish ?? '',
            'fullNameAr': personal.fullNameArabic ?? '',
            'idNumber': personal.idNumber ?? '',
            'nationality': personal.nationality ?? '',
            'dateOfBirth': personal.dateOfBirth ?? '',
            'expiryDate': personal.expiryDate ?? '',
            'gender': personal.gender ?? '',
          },
        ),
      ],
    );
  }

  /// Maps a bare trade licence extraction preview to a single-section
  /// result. No `idVerification` — that concept is Emirates-ID-only.
  ExtractedDocuments _toTradeLicenseExtractedDocuments(
    TradeLicenseExtractionResponse response,
  ) {
    final tradeLicense = response.toEntity();
    final status = _toDocumentStatus(tradeLicense.status);
    return ExtractedDocuments(
      sections: [
        ExtractedDocument(
          type: DocumentType.tradeLicense,
          fields: const [],
          status: status,
          missingFields: tradeLicense.missingFields,
          issue: deriveDocumentIssue(
            status: status,
            missingFields: tradeLicense.missingFields,
          ),
          raw: {
            'tradeNameEn': tradeLicense.tradeNameEnglish ?? '',
            'tradeNameAr': tradeLicense.tradeNameArabic ?? '',
            'licenceNo': tradeLicense.licenseNumber ?? '',
            'licenceType': tradeLicense.licenseType ?? '',
            'establishmentDate': tradeLicense.establishmentDate ?? '',
            'issuanceDate': tradeLicense.issuanceDate ?? '',
            'legalForm': tradeLicense.legalForm ?? '',
            'unifiedRegNo': tradeLicense.unifiedRegistrationNumber ?? '',
            'unifiedLicenceNo': tradeLicense.unifiedLicenseNumber ?? '',
          },
        ),
      ],
    );
  }

  DocumentStatus _toDocumentStatus(LegalDataStatus status) => switch (status) {
    LegalDataStatus.verified => DocumentStatus.verified,
    LegalDataStatus.expiringSoon => DocumentStatus.expiringSoon,
    LegalDataStatus.expired => DocumentStatus.expired,
  };
}
