import 'package:flutter/widgets.dart';

/// Presenter port for the "assigned roles" card on the worker-details
/// screen.
///
/// Lives in `presentation/services/` (like [WorkerBranchAssigner]) because
/// the RBAC role/permission data model belongs to a different package
/// (`provider_rbac`), which depends on `workers` — not the other way
/// around. Defined here so `worker_details_page` can render the card
/// without importing `provider_rbac`; the implementation is registered
/// through the service locator, inverting the dependency.
///
/// Unlike [WorkerBranchAssigner] (a sheet trigger only — branch data is
/// already embedded on [WorkerEntity]), roles are fetched via a separate
/// endpoint with no embedded field on the entity, so this port returns the
/// whole self-contained card widget rather than just a tap handler.
abstract class WorkerRoleAssigner {
  Widget buildRolesCard(String workerId);
}
