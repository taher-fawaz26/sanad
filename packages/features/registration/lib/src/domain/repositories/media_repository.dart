import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:registration/src/domain/entities/media_file_entity.dart';

/// Contract for single-file media uploads during onboarding.
abstract interface class MediaRepository {
  /// Uploads [filePath] as multipart field `file`.
  ///
  /// [authorizationToken] is the short-lived onboarding Bearer (not the
  /// session access token). [uploadKey] identifies the in-flight request so
  /// [cancelUpload] can abort it. [onProgress] receives Dio send progress
  /// as `0.0`–`1.0`.
  TaskEither<Failure, MediaFileEntity> uploadSingle({
    required String filePath,
    required String fileName,
    required String mimeType,
    required String authorizationToken,
    required String uploadKey,
    void Function(double progress)? onProgress,
  });

  /// Cancels the in-flight upload registered under [uploadKey], if any.
  void cancelUpload(String uploadKey);
}
