import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:media/media.dart';
import 'package:network/network.dart';
import 'package:organization_settings/src/data/datasources/media_upload_remote_datasource.dart';
import 'package:organization_settings/src/data/models/organization_media_response.dart';
import 'package:organization_settings/src/domain/entities/organization_media_slot.dart';

/// Sets the organization's cover/logo image via the documented two-step
/// contract: `POST media/upload-single` (via [MediaUploadRemoteDataSource])
/// returns a `mediaId`, then `PATCH {slot.endpoint} {mediaId}` applies it.
///
/// Removing an image has no documented endpoint (see
/// `OrganizationMediaRepository.removeMedia` for the resulting failure).
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
  OrganizationMediaRemoteDataSourceImpl(this._mediaUpload, this._apiClient);

  final MediaUploadRemoteDataSource _mediaUpload;
  final BaseApiClient _apiClient;

  @override
  TaskEither<Failure, OrganizationMediaResponse> uploadMedia({
    required OrganizationMediaSlot slot,
    required EditedMedia media,
    void Function(double progress)? onProgress,
  }) => _mediaUpload
      .uploadSingleBytes(
        uploadKey: slot.name,
        bytes: media.bytes,
        fileName: media.fileName,
        mimeType: media.mimeType,
        onProgress: onProgress,
      )
      .flatMap(
        (uploaded) => _apiClient
            .request<OrganizationMediaResponse>(
              path: slot.endpoint,
              method: RequestMethod.patch,
              body: {'mediaId': uploaded.id},
              parser: (data) => OrganizationMediaResponse.fromJson(
                data as Map<String, dynamic>,
              ).withUrlFallback(uploaded.url),
            ),
      );

  @override
  TaskEither<Failure, Unit> removeMedia({
    required OrganizationMediaSlot slot,
  }) => TaskEither.left(
    const BusinessRuleFailure(message: 'errors.remove_image_not_supported'),
  );

  @override
  void cancelUpload(OrganizationMediaSlot slot) =>
      _mediaUpload.cancelUpload(slot.name);
}
