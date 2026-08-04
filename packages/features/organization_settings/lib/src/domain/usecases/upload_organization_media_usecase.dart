import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:media/media.dart';
import 'package:organization_settings/src/domain/entities/organization_media_entity.dart';
import 'package:organization_settings/src/domain/entities/organization_media_slot.dart';
import 'package:organization_settings/src/domain/repositories/organization_media_repository.dart';

class UploadOrganizationMediaParams extends Equatable {
  const UploadOrganizationMediaParams({
    required this.slot,
    required this.media,
    this.onProgress,
  });

  final OrganizationMediaSlot slot;
  final EditedMedia media;
  final void Function(double progress)? onProgress;

  @override
  List<Object?> get props => [slot, media];
}

class UploadOrganizationMediaUseCase
    implements UseCase<OrganizationMediaEntity, UploadOrganizationMediaParams> {
  const UploadOrganizationMediaUseCase(this._repository);

  final OrganizationMediaRepository _repository;

  @override
  TaskEither<Failure, OrganizationMediaEntity> call(
    UploadOrganizationMediaParams params,
  ) => _repository.uploadMedia(
    slot: params.slot,
    media: params.media,
    onProgress: params.onProgress,
  );
}
