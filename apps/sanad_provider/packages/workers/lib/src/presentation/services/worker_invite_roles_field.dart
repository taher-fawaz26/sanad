import 'package:flutter/widgets.dart';
import 'package:workers/src/domain/entities/worker_type.dart';

/// The current state of the mandatory Roles field on the Add Member form.
class InviteRolesSelection {
  const InviteRolesSelection({required this.roleIds, required this.isValid});

  /// The mandatory baseline role id for the selected [WorkerType] plus any
  /// additional roles the admin picked. Normalized: deduplicated, baseline
  /// always present when [isValid] is true.
  final List<String> roleIds;

  /// `false` while the role catalog is still loading, failed to load, or the
  /// mandatory baseline role could not be resolved from it — Invite must
  /// stay disabled in that state.
  final bool isValid;
}

/// Presenter port for the mandatory "Roles" field on the Add Member form.
///
/// Lives in `presentation/services/` (like [WorkerRoleAssigner]) because the
/// RBAC role data model and its `RoleAssignmentPolicy` belong to a different
/// package (`provider_rbac`), which depends on `workers` — not the other way
/// around. Defined here so `WorkerFormBody` can render the field without
/// importing `provider_rbac`; the implementation is registered through the
/// service locator, inverting the dependency.
abstract class WorkerInviteRolesField {
  /// Builds the field (trigger + selected-role chips + sheet). The
  /// implementation resolves and locks the mandatory baseline role for
  /// [type], re-normalizing the selection whenever [type] changes, and
  /// reports the latest state via [onChanged].
  Widget build({
    required WorkerType type,
    required ValueChanged<InviteRolesSelection> onChanged,
    List<String> initialRoleIds,
  });
}
