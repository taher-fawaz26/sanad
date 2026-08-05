import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:organization_settings/src/domain/entities/organization_contact_entity.dart';
import 'package:organization_settings/src/domain/repositories/organization_contact_repository.dart';

class GetOrganizationContactUseCase
    implements UseCase<OrganizationContactEntity, NoParams> {
  const GetOrganizationContactUseCase(this._repository);

  final OrganizationContactRepository _repository;

  @override
  TaskEither<Failure, OrganizationContactEntity> call(NoParams params) =>
      _repository.getContact();
}
