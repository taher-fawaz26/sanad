import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/datasources/media_upload_remote_datasource.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/endpoints/legal_data_api_paths.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/models/legal_data_media_response.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/models/legal_data_response.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/models/national_id_extraction_response.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/models/trade_license_extraction_response.dart';

/// Remote data source for the organization legal-documents renewal flow.
///
/// Renewal is split per document: Emirates ID and trade licence each have
/// their own extract/confirm pair. Reads/writes go through [BaseApiClient]
/// (session auth via interceptor); the multipart upload delegates to the
/// shared [MediaUploadRemoteDataSource] (`POST media/upload-single`).
abstract interface class LegalDataRemoteDataSource {
  TaskEither<Failure, LegalDataResponse> fetchLegalData();

  TaskEither<Failure, LegalDataMediaResponse> uploadMedia({
    required String filePath,
    required String fileName,
    required String mimeType,
    required String uploadKey,
    void Function(double progress)? onProgress,
  });

  void cancelUpload(String uploadKey);

  /// Previews a replacement Emirates ID. The response is a bare
  /// `NationalIdExtractionDto` — no outer envelope.
  TaskEither<Failure, NationalIdExtractionResponse> extractEmiratesId({
    required String emiratesIdFrontId,
    required String emiratesIdBackId,
  });

  /// Confirms the reviewed Emirates ID extraction, replacing the stored
  /// document. Companies and individuals alike.
  TaskEither<Failure, Unit> confirmEmiratesId({
    required String emiratesIdFrontId,
    required String emiratesIdBackId,
  });

  /// Previews a replacement trade licence. Companies only. The response is a
  /// bare `TradeLicenseExtractionDto` — no outer envelope.
  TaskEither<Failure, TradeLicenseExtractionResponse> extractTradeLicense({
    required String tradeLicenseId,
  });

  /// Confirms the reviewed trade licence extraction, replacing the stored
  /// document.
  TaskEither<Failure, Unit> confirmTradeLicense({
    required String tradeLicenseId,
  });
}

class LegalDataRemoteDataSourceImpl implements LegalDataRemoteDataSource {
  LegalDataRemoteDataSourceImpl(this._apiClient, this._mediaUpload);

  final BaseApiClient _apiClient;
  final MediaUploadRemoteDataSource _mediaUpload;

  @override
  TaskEither<Failure, LegalDataResponse> fetchLegalData() =>
      _apiClient.request<LegalDataResponse>(
        path: LegalDataApiPaths.legalData,
        method: RequestMethod.get,
        parser: (data) =>
            LegalDataResponse.fromJson(data as Map<String, dynamic>),
      );

  @override
  TaskEither<Failure, LegalDataMediaResponse> uploadMedia({
    required String filePath,
    required String fileName,
    required String mimeType,
    required String uploadKey,
    void Function(double progress)? onProgress,
  }) => _mediaUpload
      .uploadSingle(
        uploadKey: uploadKey,
        filePath: filePath,
        fileName: fileName,
        mimeType: mimeType,
        onProgress: onProgress,
      )
      .map(
        (uploaded) => LegalDataMediaResponse(
          id: uploaded.id,
          url: uploaded.url,
          originalName: uploaded.originalName,
          mimeType: uploaded.mimeType,
        ),
      );

  @override
  void cancelUpload(String uploadKey) => _mediaUpload.cancelUpload(uploadKey);

  @override
  TaskEither<Failure, NationalIdExtractionResponse> extractEmiratesId({
    required String emiratesIdFrontId,
    required String emiratesIdBackId,
  }) => _apiClient.request<NationalIdExtractionResponse>(
    path: LegalDataApiPaths.emiratesIdExtract,
    method: RequestMethod.post,
    body: {
      'emiratesIdFrontId': emiratesIdFrontId,
      'emiratesIdBackId': emiratesIdBackId,
    },
    parser: (data) =>
        NationalIdExtractionResponse.fromJson(data as Map<String, dynamic>),
  );

  @override
  TaskEither<Failure, Unit> confirmEmiratesId({
    required String emiratesIdFrontId,
    required String emiratesIdBackId,
  }) => _apiClient.request<Unit>(
    path: LegalDataApiPaths.emiratesIdConfirm,
    method: RequestMethod.put,
    body: {
      'emiratesIdFrontId': emiratesIdFrontId,
      'emiratesIdBackId': emiratesIdBackId,
    },
    parser: (_) => unit,
  );

  @override
  TaskEither<Failure, TradeLicenseExtractionResponse> extractTradeLicense({
    required String tradeLicenseId,
  }) => _apiClient.request<TradeLicenseExtractionResponse>(
    path: LegalDataApiPaths.tradeLicenseExtract,
    method: RequestMethod.post,
    body: {'tradeLicenseId': tradeLicenseId},
    parser: (data) =>
        TradeLicenseExtractionResponse.fromJson(data as Map<String, dynamic>),
  );

  @override
  TaskEither<Failure, Unit> confirmTradeLicense({
    required String tradeLicenseId,
  }) => _apiClient.request<Unit>(
    path: LegalDataApiPaths.tradeLicenseConfirm,
    method: RequestMethod.put,
    body: {'tradeLicenseId': tradeLicenseId},
    parser: (_) => unit,
  );
}
