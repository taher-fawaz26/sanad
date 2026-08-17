/// Backend permission actions for the Branches feature — verified live
/// against `GET /api/v1/provider/permissions` (see the RBAC migration plan).
///
/// `static const String`, not an enum: the backend can introduce a new
/// action (e.g. a future `provider:branch:delete`) without requiring a
/// client release, and this feature only references the ones it actually
/// gates today.
///
/// There is deliberately no `delete` constant — the backend does not define
/// one yet, so branch deletion stays persona-gated (`canManageOrganization`)
/// rather than permission-gated. Inventing a client-side key here would risk
/// denying it to everyone (or granting it to no one) until the real backend
/// action ships with a possibly different name.
abstract final class BranchPermissions {
  BranchPermissions._();

  static const String view = 'provider:branch:view';
  static const String create = 'provider:branch:create';
  static const String update = 'provider:branch:update';
}
