/// Permission entry returned on authenticated session responses.
class PermissionModel {
  const PermissionModel({
    required this.name,
    this.resource,
    this.action,
  });

  final String name;
  final String? resource;
  final String? action;

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
