import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:media_upload/src/data/endpoints/media_upload_api_paths.dart';
import 'package:media_upload/src/data/models/upload_media_response.dart';
import 'package:network/network.dart';

/// The single multipart-upload implementation for the whole app — every
/// feature's `MediaUploadRepository` delegates here instead of reimplementing
/// its own `POST /media/upload-single` call.
abstract interface class MediaUploadRemoteDataSource {
  TaskEither<Failure, UploadMediaResponse> uploadSingle({
    required String uploadKey,
    required String filePath,
    required String fileName,
    required String mimeType,
    void Function(double progress)? onProgress,
  });

  /// Uploads from in-memory [bytes] instead of a file path — for assets that
  /// only exist in memory (e.g. some web sources).
  TaskEither<Failure, UploadMediaResponse> uploadSingleBytes({
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
  TaskEither<Failure, UploadMediaResponse> uploadSingle({
    required String uploadKey,
    required String filePath,
    required String fileName,
    required String mimeType,
    void Function(double progress)? onProgress,
  }) => _upload(
    uploadKey: uploadKey,
    onProgress: onProgress,
    file: () async => MultipartFile.fromFile(
      filePath,
      filename: fileName,
      contentType: DioMediaType.parse(mimeType),
    ),
  );

  @override
  TaskEither<Failure, UploadMediaResponse> uploadSingleBytes({
    required String uploadKey,
    required List<int> bytes,
    required String fileName,
    required String mimeType,
    void Function(double progress)? onProgress,
  }) => _upload(
    uploadKey: uploadKey,
    onProgress: onProgress,
    file: () async => MultipartFile.fromBytes(
      bytes,
      filename: fileName,
      contentType: DioMediaType.parse(mimeType),
    ),
  );

  TaskEither<Failure, UploadMediaResponse> _upload({
    required String uploadKey,
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
        return UploadMediaResponse.fromJson(map);
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
