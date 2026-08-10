/// `UpdateRoleDto` — body for `PATCH /api/v1/provider/roles/{id}`.
///
/// Every field is optional for a partial update; only the fields the caller
/// actually changed are included in the request body.
class UpdateRoleDto {
  const UpdateRoleDto({
    this.name,
    this.displayName,
    this.displayNameAr,
    this.description,
    this.descriptionAr,
    this.permissionIds,
  });

  final String? name;
  final String? displayName;
  final String? displayNameAr;
  final String? description;
  final String? descriptionAr;
  final List<String>? permissionIds;

  Map<String, dynamic> toJson() => {
    if (name != null) 'name': name,
    if (displayName != null) 'displayName': displayName,
    if (displayNameAr != null) 'displayNameAr': displayNameAr,
    if (description != null) 'description': description,
    if (descriptionAr != null) 'descriptionAr': descriptionAr,
    if (permissionIds != null) 'permissionIds': permissionIds,
  };
}
