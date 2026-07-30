import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';
import 'package:registration/src/data/endpoints/media_api_paths.dart';
import 'package:registration/src/data/models/media_upload_response.dart';

/// Remote data source for media uploads.
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
  }) =>
      TaskEither.tryCatch(
        () async {
          // Replace any prior in-flight upload for this slot.
          _cancelTokens[uploadKey]?.cancel();
          final cancelToken = CancelToken();
          _cancelTokens[uploadKey] = cancelToken;

          final formData = FormData.fromMap({
            'file': await MultipartFile.fromFile(
              filePath,
              filename: fileName,
            ),
          });

          try {
            final response = await _client.postMultipart<dynamic>(
              MediaApiPaths.uploadSingle,
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
            final map = raw is Map<String, dynamic>
                ? (raw['data'] as Map<String, dynamic>? ?? raw)
                : <String, dynamic>{};
            return MediaUploadResponse.fromJson(map);
          } finally {
            _cancelTokens.remove(uploadKey);
          }
        },
        (error, _) => ErrorMapper.mapError(error),
      );

  @override
  void cancelUpload(String uploadKey) {
    final token = _cancelTokens.remove(uploadKey);
    if (token != null && !token.isCancelled) {
      token.cancel();
    }
  }
}
