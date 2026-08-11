import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:document_flow/document_flow.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';
import 'package:sanad_provider/src/features/registration/src/data/endpoints/media_api_paths.dart';
import 'package:sanad_provider/src/features/registration/src/data/models/extraction_response.dart';
import 'package:sanad_provider/src/features/registration/src/data/models/media_upload_response.dart';
import 'package:sanad_provider/src/features/registration/src/data/models/profile_completion_request.dart';
import 'package:sanad_provider/src/features/registration/src/data/models/profile_completion_response.dart';

/// Remote data source for media uploads and document extraction.
abstract interface class MediaRemoteDataSource {
  TaskEither<Failure, MediaUploadResponse> uploadSingle({
    required String filePath,
    required String fileName,
    required String mimeType,
    required String authorizationToken,
    required String uploadKey,
    void Function(double progress)? onProgress,
  });

  void cancelUpload(String uploadKey);

  /// Calls `POST auth/extract` with the three uploaded media IDs and returns
  /// the structured [ExtractedDocuments].
  TaskEither<Failure, ExtractedDocuments> extractDocuments({
    required String authorizationToken,
    required String emiratesIdFrontId,
    required String emiratesIdBackId,
    String? tradeLicenseId,
  });

  /// Completes provider profile by posting to `MediaApiPaths.profile`
  /// (`POST auth/profile`).
  TaskEither<Failure, AuthSessionEntity> completeProfile({
    required String authorizationToken,
    required ProfileCompletionRequest request,
  });
}

class MediaRemoteDataSourceImpl implements MediaRemoteDataSource {
  MediaRemoteDataSourceImpl(this._client);

  final SecureDioClient _client;

  /// Active cancel tokens keyed by upload slot.
  final Map<String, CancelToken> _cancelTokens = {};

  @override
  TaskEither<Failure, MediaUploadResponse> uploadSingle({
    required String filePath,
    required String fileName,
    required String mimeType,
    required String authorizationToken,
    required String uploadKey,
    void Function(double progress)? onProgress,
  }) => TaskEither.tryCatch(
    () async {
      _cancelTokens[uploadKey]?.cancel();
      final cancelToken = CancelToken();
      _cancelTokens[uploadKey] = cancelToken;

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
          contentType: DioMediaType.parse(mimeType),
        ),
      });

      try {
        final response = await _client.postMultipart<dynamic>(
          MediaApiPaths.onboarding,
          formData: formData,
          cancelToken: cancelToken,
          options: Options(
            headers: {'Authorization': 'Bearer $authorizationToken'},
          ),
          onSendProgress: (sent, total) {
            if (total <= 0 || onProgress == null) return;
            onProgress((sent / total).clamp(0.0, 1.0));
          },
        );

        final raw = response.data;
        final map = _parseResponse(raw);

        return MediaUploadResponse.fromJson(map);
      } finally {
        _cancelTokens.remove(uploadKey);
      }
    },
    (error, stackTrace) => ErrorMapper.mapError(error),
  );

  @override
  void cancelUpload(String uploadKey) {
    final token = _cancelTokens.remove(uploadKey);
    if (token != null && !token.isCancelled) {
      token.cancel();
    }
  }

  @override
  TaskEither<Failure, ExtractedDocuments> extractDocuments({
    required String authorizationToken,
    required String emiratesIdFrontId,
    required String emiratesIdBackId,
    String? tradeLicenseId,
  }) => TaskEither.tryCatch(
    () async {
      final body = <String, dynamic>{
        'emiratesIdFrontId': emiratesIdFrontId,
        'emiratesIdBackId': emiratesIdBackId,
        if (tradeLicenseId != null) 'tradeLicenseId': tradeLicenseId,
      };

      final response = await _client.post<dynamic>(
        MediaApiPaths.extract,
        data: body,
        options: Options(
          headers: {'Authorization': 'Bearer $authorizationToken'},
        ),
      );

      final raw = response.data;
      final map = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
      return ExtractionResponse.fromJson(
        map,
        includeTradeLicence: tradeLicenseId != null,
      );
    },
    (error, _) => ErrorMapper.mapError(error),
  );

  @override
  TaskEither<Failure, AuthSessionEntity> completeProfile({
    required String authorizationToken,
    required ProfileCompletionRequest request,
  }) => TaskEither.tryCatch(
    () async {
      final response = await _client.post<dynamic>(
        MediaApiPaths.profile,
        data: request.toJson(),
        options: Options(
          headers: {'Authorization': 'Bearer $authorizationToken'},
        ),
      );

      final raw = response.data;
      final map = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
      return ProfileCompletionResponse.fromJson(map);
    },
    (error, _) => ErrorMapper.mapError(error),
  );

  /// Parses the onboarding upload response body.
  static Map<String, dynamic> _parseResponse(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is Map<String, dynamic>) return data;
      return raw;
    }
    if (raw is List && raw.isNotEmpty) {
      final first = raw.first;
      if (first is Map<String, dynamic>) return first;
    }
    return <String, dynamic>{};
  }
}
