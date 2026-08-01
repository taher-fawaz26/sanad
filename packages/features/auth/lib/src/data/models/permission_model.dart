import 'package:auth/src/domain/entities/permission_entity.dart';

/// Data model for [PermissionEntity] — inherits fields, adds JSON I/O.
class PermissionModel extends PermissionEntity {
  const PermissionModel({
    required super.name,
    super.resource,
    super.action,
  });

  factory PermissionModel.fromJson(Map<String, dynamic> json) {
    return PermissionModel(
      name: (json['name'] as String?) ??
          (json['permission'] as String?) ??
          '',
      resource: json['resource'] as String?,
      action: json['action'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        if (resource != null) 'resource': resource,
        if (action != null) 'action': action,
      };
}
