/// `CreateRoleDto` — body for `POST /api/v1/provider/roles`.
class CreateRoleDto {
  const CreateRoleDto({
    required this.name,
    required this.displayName,
    required this.permissionIds,
    this.description,
  });

  final String name;
  final String displayName;
  final String? description;
  final List<String> permissionIds;

  Map<String, dynamic> toJson() => {
    'name': name,
    'displayName': displayName,
    if (description != null) 'description': description,
    'permissionIds': permissionIds,
  };
}
