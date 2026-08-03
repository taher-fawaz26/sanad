import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';
import 'package:registration/src/data/datasources/media_remote_datasource.dart';
import 'package:registration/src/data/models/extraction_result.dart';
import 'package:registration/src/data/models/profile_completion_request.dart';
import 'package:registration/src/domain/entities/media_file_entity.dart';
import 'package:registration/src/domain/repositories/media_repository.dart';

class MediaRepositoryImpl implements MediaRepository {
  const MediaRepositoryImpl(this._remote, this._networkGuard);

  final MediaRemoteDataSource _remote;
  final NetworkGuard _networkGuard;

  @override
  TaskEither<Failure, MediaFileEntity> uploadSingle({
    required String filePath,
    required String fileName,
    required String mimeType,
    required String authorizationToken,
    required String uploadKey,
    void Function(double progress)? onProgress,
  }) => _networkGuard.execute(
    action: _remote
        .uploadSingle(
          filePath: filePath,
          fileName: fileName,
          mimeType: mimeType,
          authorizationToken: authorizationToken,
          uploadKey: uploadKey,
          onProgress: onProgress,
        )
        .map((response) => response.toEntity()),
  );

  @override
  void cancelUpload(String uploadKey) => _remote.cancelUpload(uploadKey);

  @override
  TaskEither<Failure, ExtractionResult> extractDocuments({
    required String authorizationToken,
    required String emiratesIdFrontId,
    required String emiratesIdBackId,
    String? tradeLicenseId,
  }) => _networkGuard.execute(
    action: _remote.extractDocuments(
      authorizationToken: authorizationToken,
      emiratesIdFrontId: emiratesIdFrontId,
      emiratesIdBackId: emiratesIdBackId,
      tradeLicenseId: tradeLicenseId,
    ),
  );

  @override
  TaskEither<Failure, AuthSessionEntity> completeProfile({
    required String authorizationToken,
    required String endpoint,
    required ProfileCompletionRequest request,
  }) => _networkGuard.execute(
    action: _remote.completeProfile(
      authorizationToken: authorizationToken,
      endpoint: endpoint,
      request: request,
    ),
  );
}
