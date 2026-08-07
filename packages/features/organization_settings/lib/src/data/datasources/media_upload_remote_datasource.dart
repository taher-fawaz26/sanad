import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';
import 'package:organization_settings/src/data/endpoints/media_upload_api_paths.dart';
import 'package:organization_settings/src/data/models/uploaded_media_response.dart';

/// Shared authenticated media upload — the first half of every two-step
/// upload flow in this feature (cover/logo images, legal documents).
///
/// `POST /media/upload-single` returns a `mediaId`; callers then PATCH/PUT
/// that id into the resource it belongs to. Kept here rather than duplicated
/// per-flow so there is exactly one multipart-upload implementation.
abstract interface class MediaUploadRemoteDataSource {
  TaskEither<Failure, UploadedMediaResponse> uploadSingle({
    required String uploadKey,
    required String filePath,
    required String fileName,
    required String mimeType,
    void Function(double progress)? onProgress,
  });

  /// Uploads from in-memory [bytes] instead of a file path (e.g. media the
  /// `media` package has already decoded/edited in memory).
  TaskEither<Failure, UploadedMediaResponse> uploadSingleBytes({
    required String uploadKey,
    required List<int> bytes,
    required String fileName,
    required String mimeType,
    void Function(double progress)? onProgress,
  });

  void cancelUpload(String uploadKey);
}

class MediaUploadRemoteDataSourceImpl implements MediaUploadRemoteDataSource {
  MediaUploadRemoteDataSourceImpl(this._client);

  final SecureDioClient _client;

  final Map<String, CancelToken> _cancelTokens = {};

  @override
  TaskEither<Failure, UploadedMediaResponse> uploadSingle({
    required String uploadKey,
    required String filePath,
    required String fileName,
    required String mimeType,
    void Function(double progress)? onProgress,
  }) => _upload(
    uploadKey: uploadKey,
    fileName: fileName,
    mimeType: mimeType,
    onProgress: onProgress,
    file: () async => MultipartFile.fromFile(
      filePath,
      filename: fileName,
      contentType: DioMediaType.parse(mimeType),
    ),
  );

  @override
  TaskEither<Failure, UploadedMediaResponse> uploadSingleBytes({
    required String uploadKey,
    required List<int> bytes,
    required String fileName,
    required String mimeType,
    void Function(double progress)? onProgress,
  }) => _upload(
    uploadKey: uploadKey,
    fileName: fileName,
    mimeType: mimeType,
    onProgress: onProgress,
    file: () async => MultipartFile.fromBytes(
      bytes,
      filename: fileName,
      contentType: DioMediaType.parse(mimeType),
    ),
  );

  TaskEither<Failure, UploadedMediaResponse> _upload({
    required String uploadKey,
    required String fileName,
    required String mimeType,
    required Future<MultipartFile> Function() file,
    void Function(double progress)? onProgress,
  }) => TaskEither.tryCatch(
    () async {
      _cancelTokens[uploadKey]?.cancel();
      final cancelToken = CancelToken();
      _cancelTokens[uploadKey] = cancelToken;

      final formData = FormData.fromMap({'file': await file()});

      try {
        final response = await _client.postMultipart<dynamic>(
          MediaUploadApiPaths.uploadSingle,
          formData: formData,
          cancelToken: cancelToken,
          onSendProgress: (sent, total) {
            if (total <= 0 || onProgress == null) return;
            onProgress((sent / total).clamp(0.0, 1.0));
          },
        );

        final raw = response.data;
        final map = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
        return UploadedMediaResponse.fromJson(map);
      } finally {
        _cancelTokens.remove(uploadKey);
      }
    },
    (error, _) => ErrorMapper.mapError(error),
  );

  @override
  void cancelUpload(String uploadKey) {
    final token = _cancelTokens.remove(uploadKey);
    if (token != null && !token.isCancelled) token.cancel();
  }
}
