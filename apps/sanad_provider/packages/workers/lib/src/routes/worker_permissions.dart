/// Backend permission actions for the Workers feature — verified live
/// against `GET /api/v1/provider/permissions` (see the RBAC migration plan).
///
/// `static const String`, not an enum — same reasoning as `BranchPermissions`
/// / `ServicePermissions`: the backend can add an action without a client
/// release.
///
/// There is deliberately no `create`/`update`/`delete` constant here.
/// Inviting a worker (`POST /workers/invitations`) is owner-only persona
/// (RBAC Phase 7 finding F1 — it 403s for a manager holding every catalog
/// permission), not permission-gated, and no permission exists for editing
/// or removing a worker either — those writes stay persona-gated.
abstract final class WorkerPermissions {
  WorkerPermissions._();

  static const String view = 'provider:worker:view';
}
