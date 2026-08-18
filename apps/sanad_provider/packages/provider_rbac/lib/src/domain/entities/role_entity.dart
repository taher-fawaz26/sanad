import 'package:equatable/equatable.dart';
import 'package:provider_rbac/src/domain/entities/permission_entity.dart';
import 'package:provider_rbac/src/domain/entities/role_persona_type.dart';

/// A role template (`GET/POST/PATCH /api/v1/provider/roles`).
class RoleEntity extends Equatable {
  const RoleEntity({
    required this.id,
    required this.name,
    required this.displayName,
    required this.userType,
    required this.isSystem,
    required this.permissions,
    this.description,
  });

  final String id;

  /// e.g. `branch-manager`.
  final String name;
  final String displayName;
  final String? description;
  final RolePersonaType userType;

  /// System templates are read-only; custom roles belong to the caller's
  /// organization.
  final bool isSystem;
  final List<PermissionEntity> permissions;

  @override
  List<Object?> get props => [
    id,
    name,
    displayName,
    description,
    userType,
    isSystem,
    permissions,
  ];
}
