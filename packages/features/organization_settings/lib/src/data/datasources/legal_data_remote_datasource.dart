import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';
import 'package:organization_settings/src/data/datasources/media_upload_remote_datasource.dart';
import 'package:organization_settings/src/data/endpoints/legal_data_api_paths.dart';
import 'package:organization_settings/src/data/models/legal_data_extraction_response.dart';
import 'package:organization_settings/src/data/models/legal_data_media_response.dart';
import 'package:organization_settings/src/data/models/legal_data_response.dart';

/// Remote data source for the organization legal-documents update flow.
///
/// Reads/writes go through [BaseApiClient] (session auth via interceptor);
/// the multipart upload delegates to the shared
/// [MediaUploadRemoteDataSource] (`POST media/upload-single`) — the same
/// documented endpoint the cover/logo image flow uses — rather than the
/// previously-guessed `service-provider/legal-data/media`.
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

  TaskEither<Failure, LegalDataExtractionResponse> extract({
    required String emiratesIdFrontId,
    required String emiratesIdBackId,
    String? tradeLicenseId,
  });

  TaskEither<Failure, Unit> updateDocuments({
    required String emiratesIdFrontId,
    required String emiratesIdBackId,
    String? tradeLicenseId,
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
  TaskEither<Failure, LegalDataExtractionResponse> extract({
    required String emiratesIdFrontId,
    required String emiratesIdBackId,
    String? tradeLicenseId,
  }) => _apiClient.request<LegalDataExtractionResponse>(
    path: LegalDataApiPaths.extract,
    method: RequestMethod.post,
    body: {
      'emiratesIdFrontId': emiratesIdFrontId,
      'emiratesIdBackId': emiratesIdBackId,
      if (tradeLicenseId != null) 'tradeLicenseId': tradeLicenseId,
    },
    parser: (data) =>
        LegalDataExtractionResponse.fromJson(data as Map<String, dynamic>),
  );

  @override
  TaskEither<Failure, Unit> updateDocuments({
    required String emiratesIdFrontId,
    required String emiratesIdBackId,
    String? tradeLicenseId,
  }) => _apiClient.request<Unit>(
    path: LegalDataApiPaths.documents,
    method: RequestMethod.put,
    body: {
      'emiratesIdFrontId': emiratesIdFrontId,
      'emiratesIdBackId': emiratesIdBackId,
      if (tradeLicenseId != null) 'tradeLicenseId': tradeLicenseId,
    },
    parser: (_) => unit,
  );
}
