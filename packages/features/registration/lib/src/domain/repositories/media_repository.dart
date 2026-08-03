import 'package:auth/auth.dart' show AuthSessionEntity;
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:registration/src/data/models/extraction_result.dart';
import 'package:registration/src/data/models/profile_completion_request.dart';
import 'package:registration/src/domain/entities/media_file_entity.dart';

/// Contract for single-file media uploads and document extraction during
/// onboarding.
abstract interface class MediaRepository {
  /// Uploads [filePath] as multipart field `file` to `POST media/onboarding`.
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

  /// Calls `POST auth/extract` to extract structured data from uploaded IDs.
  TaskEither<Failure, ExtractionResult> extractDocuments({
    required String authorizationToken,
    required String emiratesIdFrontId,
    required String emiratesIdBackId,
    String? tradeLicenseId,
  });

  /// Completes the provider profile.
  ///
  /// [endpoint] is the type-specific path (`auth/profile/individual-provider`,
  /// `auth/profile/company-provider`, etc.) supplied by [ProviderTypeSpec].
  /// Adding a new provider type requires no change to this interface.
  TaskEither<Failure, AuthSessionEntity> completeProfile({
    required String authorizationToken,
    required String endpoint,
    required ProfileCompletionRequest request,
  });
}
