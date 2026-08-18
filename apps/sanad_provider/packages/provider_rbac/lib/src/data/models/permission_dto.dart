import 'package:provider_rbac/src/domain/entities/permission_entity.dart';

class PermissionDto {
  const PermissionDto({
    required this.id,
    required this.action,
    required this.displayName,
    required this.resource,
    this.description,
    this.isAdmin = false,
  });

  factory PermissionDto.fromJson(Map<String, dynamic> json) => PermissionDto(
    id: json['id'] as String,
    action: json['action'] as String,
    displayName: json['displayName'] as String,
    description: json['description'] as String?,
    resource: json['resource'] as String,
    // Required in the live contract, but tolerate absence defensively.
    isAdmin: json['isAdmin'] as bool? ?? false,
  );

  final String id;
  final String action;
  final String displayName;
  final String? description;
  final String resource;
  final bool isAdmin;

  PermissionEntity toEntity() => PermissionEntity(
    id: id,
    action: action,
    displayName: displayName,
    description: description,
    resource: resource,
    isAdmin: isAdmin,
  );
}
