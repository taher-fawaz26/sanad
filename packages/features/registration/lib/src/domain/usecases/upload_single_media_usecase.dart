import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:registration/src/domain/entities/media_file_entity.dart';
import 'package:registration/src/domain/repositories/media_repository.dart';

/// Params for [UploadSingleMediaUseCase].
class UploadSingleMediaParams extends Equatable {
  const UploadSingleMediaParams({
    required this.filePath,
    required this.fileName,
    required this.mimeType,
    required this.authorizationToken,
    required this.uploadKey,
    this.onProgress,
  });

  final String filePath;
  final String fileName;
  final String mimeType;

  /// Onboarding Bearer used to authorize the upload.
  final String authorizationToken;

  /// Stable key for cancel (e.g. document slot name).
  final String uploadKey;

  /// Real Dio `onSendProgress` fraction (`0.0`–`1.0`).
  final void Function(double progress)? onProgress;

  @override
  List<Object?> get props => [
        filePath,
        fileName,
        mimeType,
        authorizationToken,
        uploadKey,
      ];
}

/// Uploads one file via `POST media/onboarding`.
///
/// Cancel tokens stay in the data layer — call [cancel] with the same
/// [UploadSingleMediaParams.uploadKey] to abort the HTTP request.
class UploadSingleMediaUseCase
    implements UseCase<MediaFileEntity, UploadSingleMediaParams> {
  const UploadSingleMediaUseCase(this._repository);

  final MediaRepository _repository;

  @override
  TaskEither<Failure, MediaFileEntity> call(UploadSingleMediaParams params) =>
      _repository.uploadSingle(
        filePath: params.filePath,
        fileName: params.fileName,
        mimeType: params.mimeType,
        authorizationToken: params.authorizationToken,
        uploadKey: params.uploadKey,
        onProgress: params.onProgress,
      );

  /// Aborts the in-flight upload for [uploadKey], if any.
  void cancel(String uploadKey) => _repository.cancelUpload(uploadKey);
}
