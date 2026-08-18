import 'package:core/core.dart';
import 'package:flutter/widgets.dart';
import 'package:provider_rbac/src/domain/usecases/get_roles_usecase.dart';
import 'package:provider_rbac/src/presentation/widgets/invite_roles_field.dart';
import 'package:workers/workers.dart';

/// Implements the `workers`-defined [WorkerInviteRolesField] port so
/// `WorkerFormBody` can render the mandatory Roles field without depending
/// on `provider_rbac` — mirrors how [ProviderRbacWorkerRoleAssigner]
/// inverts the same dependency for the worker-details "assigned roles" card.
class ProviderRbacWorkerInviteRolesField implements WorkerInviteRolesField {
  const ProviderRbacWorkerInviteRolesField();

  @override
  Widget build({
    required WorkerType type,
    required ValueChanged<InviteRolesSelection> onChanged,
    List<String> initialRoleIds = const [],
  }) => InviteRolesField(
    type: type,
    onChanged: onChanged,
    getRolesUseCase: sl<GetRolesUseCase>(),
    initialRoleIds: initialRoleIds,
  );
}
