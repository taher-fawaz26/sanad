/// Backend permission actions for the Services feature — verified live
/// against `GET /api/v1/provider/permissions` (see the RBAC migration plan).
///
/// `static const String`, not an enum: the backend can introduce a new
/// action without requiring a client release, and this feature only
/// references the ones it actually gates today.
///
/// There is deliberately no `create`/`update`/`delete` constant here — the
/// backend defines no such permissions for provider-services yet, so those
/// writes stay persona-gated rather than permission-gated (same reasoning
/// as `BranchPermissions` omitting `delete`). `catalogView` is the catalog
/// (`GET /categories`/`GET /services`) permission, distinct from
/// `providerServiceView` (`GET /provider-services`, this provider's own
/// listings) — the backend defines them as two separate actions.
abstract final class ServicePermissions {
  ServicePermissions._();

  static const String providerServiceView = 'provider:provider-service:view';
  static const String catalogView = 'provider:catalog-service:view';
}
