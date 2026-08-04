import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:media/media.dart';
import 'package:network/network.dart';
import 'package:organization_settings/src/data/models/organization_media_response.dart';
import 'package:organization_settings/src/domain/entities/organization_media_slot.dart';

/// Uploads/removes organization identity images via multipart HTTP.
///
/// Uses [SecureDioClient] (the `authDio` instance), whose `AuthInterceptor`
/// attaches the session token automatically — so no `Authorization` header is
/// set here. Cancel tokens are keyed per slot so a re-pick cancels the prior
/// in-flight upload for that slot.
abstract interface class OrganizationMediaRemoteDataSource {
  TaskEither<Failure, OrganizationMediaResponse> uploadMedia({
    required OrganizationMediaSlot slot,
    required EditedMedia media,
    void Function(double progress)? onProgress,
  });

  TaskEither<Failure, Unit> removeMedia({required OrganizationMediaSlot slot});

  void cancelUpload(OrganizationMediaSlot slot);
}

class OrganizationMediaRemoteDataSourceImpl
    implements OrganizationMediaRemoteDataSource {
  OrganizationMediaRemoteDataSourceImpl(this._client);

  final SecureDioClient _client;

  final Map<OrganizationMediaSlot, CancelToken> _cancelTokens = {};

  @override
  TaskEither<Failure, OrganizationMediaResponse> uploadMedia({
    required OrganizationMediaSlot slot,
    required EditedMedia media,
    void Function(double progress)? onProgress,
  }) => TaskEither.tryCatch(
    () async {
      _cancelTokens[slot]?.cancel();
      final cancelToken = CancelToken();
      _cancelTokens[slot] = cancelToken;

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          media.bytes,
          filename: media.fileName,
          contentType: DioMediaType.parse(media.mimeType),
        ),
      });

      try {
        final response = await _client.postMultipart<dynamic>(
          slot.endpoint,
          formData: formData,
          cancelToken: cancelToken,
          onSendProgress: (sent, total) {
            if (total <= 0 || onProgress == null) return;
            onProgress((sent / total).clamp(0.0, 1.0));
          },
        );

        final raw = response.data;
        final map = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
        return OrganizationMediaResponse.fromJson(map);
      } finally {
        _cancelTokens.remove(slot);
      }
    },
    (error, _) => ErrorMapper.mapError(error),
  );

  @override
  TaskEither<Failure, Unit> removeMedia({
    required OrganizationMediaSlot slot,
  }) => TaskEither.tryCatch(() async {
    await _client.delete<dynamic>(slot.endpoint);
    return unit;
  }, (error, _) => ErrorMapper.mapError(error));

  @override
  void cancelUpload(OrganizationMediaSlot slot) {
    final token = _cancelTokens.remove(slot);
    if (token != null && !token.isCancelled) token.cancel();
  }
}
