import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:provider_rbac/src/domain/entities/role_entity.dart';
import 'package:provider_rbac/src/domain/repositories/roles_repository.dart';

class UpdateRoleParams extends Equatable {
  const UpdateRoleParams({
    required this.id,
    this.name,
    this.displayName,
    this.displayNameAr,
    this.description,
    this.descriptionAr,
    this.permissionIds,
  });

  final String id;
  final String? name;
  final String? displayName;
  final String? displayNameAr;
  final String? description;
  final String? descriptionAr;
  final List<String>? permissionIds;

  @override
  List<Object?> get props => [
    id,
    name,
    displayName,
    displayNameAr,
    description,
    descriptionAr,
    permissionIds,
  ];
}

class UpdateRoleUseCase implements UseCase<RoleEntity, UpdateRoleParams> {
  const UpdateRoleUseCase(this._repository);

  final RolesRepository _repository;

  @override
  TaskEither<Failure, RoleEntity> call(UpdateRoleParams params) =>
      _repository.updateRole(
        id: params.id,
        name: params.name,
        displayName: params.displayName,
        displayNameAr: params.displayNameAr,
        description: params.description,
        descriptionAr: params.descriptionAr,
        permissionIds: params.permissionIds,
      );
}
