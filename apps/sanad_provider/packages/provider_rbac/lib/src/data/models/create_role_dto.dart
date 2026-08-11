/// `CreateRoleDto` — body for `POST /api/v1/provider/roles`.
class CreateRoleDto {
  const CreateRoleDto({
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

  Map<String, dynamic> toJson() => {
    'name': name,
    'displayName': displayName,
    if (displayNameAr != null) 'displayNameAr': displayNameAr,
    if (description != null) 'description': description,
    if (descriptionAr != null) 'descriptionAr': descriptionAr,
    'permissionIds': permissionIds,
  };
}
