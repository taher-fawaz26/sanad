import 'package:flutter/widgets.dart';
import 'package:workers/src/domain/entities/worker_entity.dart';

/// Presenter port for the "assign a branch to a worker" UI.
///
/// Lives in `presentation/services/` because the abstraction carries a
/// [BuildContext] — it is a UI adapter, not a domain rule. Defined in
/// `workers` so `worker_details_page` can trigger the flow without importing
/// `branches`; the implementation lives in `branches` (which already depends
/// on `workers`) and is registered through the service locator, inverting the
/// dependency.
abstract class WorkerBranchAssigner {
  Future<void> showAssignBranchSheet({
    required BuildContext context,
    required WorkerEntity worker,
    required ValueChanged<WorkerEntity> onWorkerUpdated,
  });
}
