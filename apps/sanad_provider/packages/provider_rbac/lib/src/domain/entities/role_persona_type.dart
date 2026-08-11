/// Which persona a role *template* applies to.
///
/// This is an RBAC-only scoping concept, distinct from `auth`'s `UserType`
/// enum. It comes from the live `RoleResponseDto.userType` field and has
/// exactly 5 values — notably `companyProvider` (NOT `organizationProvider`)
/// and no `manager` value. Do not conflate the two enums.
enum RolePersonaType {
  admin,
  client,
  individualProvider,
  companyProvider,
  worker
  ;

  static RolePersonaType fromApi(String value) => switch (value) {
    'admin' => RolePersonaType.admin,
    'client' => RolePersonaType.client,
    'individualProvider' => RolePersonaType.individualProvider,
    'companyProvider' => RolePersonaType.companyProvider,
    'worker' => RolePersonaType.worker,
    _ => RolePersonaType.worker,
  };

  String toApi() => switch (this) {
    RolePersonaType.admin => 'admin',
    RolePersonaType.client => 'client',
    RolePersonaType.individualProvider => 'individualProvider',
    RolePersonaType.companyProvider => 'companyProvider',
    RolePersonaType.worker => 'worker',
  };
}
