import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:media/media.dart';
import 'package:network/network.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/datasources/organization_media_remote_datasource.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/organization_media_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/organization_media_slot.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/repositories/organization_media_repository.dart';

class OrganizationMediaRepositoryImpl implements OrganizationMediaRepository {
  const OrganizationMediaRepositoryImpl(this._remote, this._networkGuard);

  final OrganizationMediaRemoteDataSource _remote;
  final NetworkGuard _networkGuard;

  @override
  TaskEither<Failure, OrganizationMediaEntity> uploadMedia({
    required OrganizationMediaSlot slot,
    required EditedMedia media,
    void Function(double progress)? onProgress,
  }) => _networkGuard.execute(
    action: _remote
        .uploadMedia(slot: slot, media: media, onProgress: onProgress)
        .map((response) => response.toEntity()),
  );

  @override
  TaskEither<Failure, Unit> removeMedia({
    required OrganizationMediaSlot slot,
  }) => _networkGuard.execute(action: _remote.removeMedia(slot: slot));

  @override
  void cancelUpload(OrganizationMediaSlot slot) => _remote.cancelUpload(slot);
}
