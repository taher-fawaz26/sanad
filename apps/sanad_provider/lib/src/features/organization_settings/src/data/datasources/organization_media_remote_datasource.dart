import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:media/media.dart';
import 'package:network/network.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/datasources/media_upload_remote_datasource.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/models/organization_media_response.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/organization_media_slot.dart';

/// Sets or clears the organization's cover/logo image.
///
/// Setting uses the documented two-step contract: `POST media/upload-single`
/// (via [MediaUploadRemoteDataSource]) returns a `mediaId`, then
/// `PATCH {slot.endpoint} {mediaId}` applies it.
///
/// Clearing reuses the *same* PATCH endpoint with `mediaId: null` — there is
/// no separate delete endpoint, and the client never touches storage
/// directly. Each slot has its own endpoint, so an operation on one image
/// cannot disturb the other.
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
        (uploaded) => _apiClient.request<OrganizationMediaResponse>(
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
  }) => _apiClient.request<Unit>(
    path: slot.endpoint,
    method: RequestMethod.patch,
    // `mediaId` is *required* by `UpdateServiceProviderMediaDto` — the key
    // must be present and explicitly null. An empty body is a 400, not a
    // no-op. Only this slot's field is sent, so the other image is untouched.
    body: const {'mediaId': null},
    // The response echoes `{mediaId: null}`; there is nothing to read back.
    parser: (_) => unit,
  );

  @override
  void cancelUpload(OrganizationMediaSlot slot) =>
      _mediaUpload.cancelUpload(slot.name);
}
