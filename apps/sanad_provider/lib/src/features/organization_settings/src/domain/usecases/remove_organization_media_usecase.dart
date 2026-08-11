import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/organization_media_slot.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/repositories/organization_media_repository.dart';

class RemoveOrganizationMediaParams extends Equatable {
  const RemoveOrganizationMediaParams({required this.slot});

  final OrganizationMediaSlot slot;

  @override
  List<Object?> get props => [slot];
}

class RemoveOrganizationMediaUseCase
    implements UseCase<Unit, RemoveOrganizationMediaParams> {
  const RemoveOrganizationMediaUseCase(this._repository);

  final OrganizationMediaRepository _repository;

  @override
  TaskEither<Failure, Unit> call(RemoveOrganizationMediaParams params) =>
      _repository.removeMedia(slot: params.slot);
}
