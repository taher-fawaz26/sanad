import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:provider_rbac/src/domain/entities/role_entity.dart';
import 'package:provider_rbac/src/domain/repositories/roles_repository.dart';

class CreateRoleParams extends Equatable {
  const CreateRoleParams({
    required this.name,
    required this.displayName,
    required this.permissionIds,
    this.displayNameAr,
    this.description,
    this.descriptionAr,
  });

  final String name;
  final String displayName;
  final String? displayNameAr;
  final String? description;
  final String? descriptionAr;
  final List<String> permissionIds;

  @override
  List<Object?> get props => [
    name,
    displayName,
    displayNameAr,
    description,
    descriptionAr,
    permissionIds,
  ];
}

class CreateRoleUseCase implements UseCase<RoleEntity, CreateRoleParams> {
  const CreateRoleUseCase(this._repository);

  final RolesRepository _repository;

  @override
  TaskEither<Failure, RoleEntity> call(CreateRoleParams params) =>
      _repository.createRole(
        name: params.name,
        displayName: params.displayName,
        displayNameAr: params.displayNameAr,
        description: params.description,
        descriptionAr: params.descriptionAr,
        permissionIds: params.permissionIds,
      );
}
