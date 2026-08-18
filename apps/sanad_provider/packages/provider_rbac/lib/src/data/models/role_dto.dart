import 'package:provider_rbac/src/data/models/permission_dto.dart';
import 'package:provider_rbac/src/domain/entities/role_entity.dart';
import 'package:provider_rbac/src/domain/entities/role_persona_type.dart';

class RoleDto {
  const RoleDto({
    required this.id,
    required this.name,
    required this.displayName,
    required this.userType,
    required this.isSystem,
    required this.permissions,
    this.description,
  });

  factory RoleDto.fromJson(Map<String, dynamic> json) => RoleDto(
    id: json['id'] as String,
    name: json['name'] as String,
    displayName: json['displayName'] as String,
    description: json['description'] as String?,
    userType: RolePersonaType.fromApi(json['userType'] as String),
    isSystem: json['isSystem'] as bool,
    permissions: (json['permissions'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(PermissionDto.fromJson)
        .toList(),
  );

  final String id;
  final String name;
  final String displayName;
  final String? description;
  final RolePersonaType userType;
  final bool isSystem;
  final List<PermissionDto> permissions;

  RoleEntity toEntity() => RoleEntity(
    id: id,
    name: name,
    displayName: displayName,
    description: description,
    userType: userType,
    isSystem: isSystem,
    permissions: permissions.map((p) => p.toEntity()).toList(),
  );
}
