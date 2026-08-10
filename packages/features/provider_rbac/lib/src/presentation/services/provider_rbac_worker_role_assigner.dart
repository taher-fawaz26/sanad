import 'package:flutter/widgets.dart';
import 'package:provider_rbac/src/presentation/widgets/worker_roles_card.dart';
import 'package:workers/workers.dart';

/// Implements the `workers`-defined [WorkerRoleAssigner] port so
/// `worker_details_page` can render the assigned-roles card without
/// depending on `provider_rbac` — mirrors how `branches` implements
/// `WorkerBranchAssigner` for the assigned-branches card.
class ProviderRbacWorkerRoleAssigner implements WorkerRoleAssigner {
  const ProviderRbacWorkerRoleAssigner();

  @override
  Widget buildRolesCard(String workerId) => WorkerRolesCard(workerId: workerId);
}
