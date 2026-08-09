import 'package:asset_picker/asset_picker.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:media_upload/src/data/datasources/media_upload_remote_datasource.dart';
import 'package:media_upload/src/domain/entities/uploaded_media.dart';
import 'package:media_upload/src/domain/repositories/media_upload_repository.dart';

class MediaUploadRepositoryImpl implements MediaUploadRepository {
  MediaUploadRepositoryImpl(this._dataSource);

  final MediaUploadRemoteDataSource _dataSource;

  @override
  TaskEither<Failure, UploadedMedia> upload({
    required String uploadKey,
    required PickedAsset asset,
    void Function(double progress)? onProgress,
  }) {
    final bytes = asset.bytes;
    final result = bytes != null
        ? _dataSource.uploadSingleBytes(
            uploadKey: uploadKey,
            bytes: bytes,
            fileName: asset.name,
            mimeType: asset.mimeType,
            onProgress: onProgress,
          )
        : _dataSource.uploadSingle(
            uploadKey: uploadKey,
            filePath: asset.path,
            fileName: asset.name,
            mimeType: asset.mimeType,
            onProgress: onProgress,
          );

    return result.map((response) => response.toEntity());
  }

  @override
  void cancelUpload(String uploadKey) => _dataSource.cancelUpload(uploadKey);
}
