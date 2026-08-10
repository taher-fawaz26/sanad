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
    this.displayNameAr,
    this.description,
    this.descriptionAr,
  });

  factory RoleDto.fromJson(Map<String, dynamic> json) => RoleDto(
    id: json['id'] as String,
    name: json['name'] as String,
    displayName: json['displayName'] as String,
    displayNameAr: json['displayNameAr'] as String?,
    description: json['description'] as String?,
    descriptionAr: json['descriptionAr'] as String?,
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
  final String? displayNameAr;
  final String? description;
  final String? descriptionAr;
  final RolePersonaType userType;
  final bool isSystem;
  final List<PermissionDto> permissions;

  RoleEntity toEntity() => RoleEntity(
    id: id,
    name: name,
    displayName: displayName,
    displayNameAr: displayNameAr,
    description: description,
    descriptionAr: descriptionAr,
    userType: userType,
    isSystem: isSystem,
    permissions: permissions.map((p) => p.toEntity()).toList(),
  );
}
