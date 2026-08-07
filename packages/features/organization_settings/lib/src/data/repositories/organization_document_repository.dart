import 'package:core/core.dart';
import 'package:document_flow/document_flow.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';
import 'package:organization_settings/src/data/datasources/legal_data_remote_datasource.dart';
import 'package:organization_settings/src/data/models/legal_data_response.dart';
import 'package:organization_settings/src/domain/entities/personal_legal_data_entity.dart';
import 'package:organization_settings/src/domain/entities/trade_license_legal_data_entity.dart';

/// Organization Settings' [DocumentFlowRepository] implementation.
///
/// Backs the shared upload/extract/submit pipeline with the
/// `service-provider/legal-data*` endpoints. Unlike registration, this flow
/// runs under an authenticated session — [DocumentFlowContext] stays empty;
/// the session token is attached automatically by the network layer.
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
    final frontId = params.uploadedIds[DocumentType.emiratesIdFront];
    final backId = params.uploadedIds[DocumentType.emiratesIdBack];
    if (frontId == null || backId == null) {
      return TaskEither.left(
        const ValidationFailure(message: 'errors.required_fields_missing'),
      );
    }
    return _networkGuard
        .execute(
          action: _remote.extract(
            emiratesIdFrontId: frontId,
            emiratesIdBackId: backId,
            tradeLicenseId: params.uploadedIds[DocumentType.tradeLicense],
          ),
        )
        .map(_toExtractedDocuments);
  }

  @override
  TaskEither<Failure, Unit> submit(SubmitParams params) {
    final frontId = params.uploadedIds[DocumentType.emiratesIdFront];
    final backId = params.uploadedIds[DocumentType.emiratesIdBack];
    if (frontId == null || backId == null) {
      return TaskEither.left(
        const ValidationFailure(message: 'errors.required_fields_missing'),
      );
    }
    return _networkGuard.execute(
      action: _remote.updateDocuments(
        emiratesIdFrontId: frontId,
        emiratesIdBackId: backId,
        tradeLicenseId: params.uploadedIds[DocumentType.tradeLicense],
      ),
    );
  }

  @override
  TaskEither<Failure, ExtractedDocuments> fetch(FetchParams params) =>
      _networkGuard
          .execute(action: _remote.fetchLegalData())
          .map(_toExtractedDocuments);

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
      issue: personal.isExpired ? DocumentIssue.expired : DocumentIssue.none,
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
    issue: tradeLicense.isExpired ? DocumentIssue.expired : DocumentIssue.none,
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
}
