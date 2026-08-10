import 'package:provider_rbac/src/domain/entities/permission_entity.dart';

class PermissionDto {
  const PermissionDto({
    required this.id,
    required this.action,
    required this.displayName,
    required this.resource,
    this.displayNameAr,
    this.description,
  });

  factory PermissionDto.fromJson(Map<String, dynamic> json) => PermissionDto(
    id: json['id'] as String,
    action: json['action'] as String,
    displayName: json['displayName'] as String,
    displayNameAr: json['displayNameAr'] as String?,
    description: json['description'] as String?,
    resource: json['resource'] as String,
  );

  final String id;
  final String action;
  final String displayName;
  final String? displayNameAr;
  final String? description;
  final String resource;

  PermissionEntity toEntity() => PermissionEntity(
    id: id,
    action: action,
    displayName: displayName,
    displayNameAr: displayNameAr,
    description: description,
    resource: resource,
  );
}
