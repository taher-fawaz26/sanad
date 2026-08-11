/// `AssignWorkerRolesDto` — body for
/// `POST /api/v1/workers/{workerId}/roles`.
///
/// [roleIds] *replaces* the worker's existing roles (per the live schema),
/// it is not additive. An empty list is valid and clears all roles.
class AssignWorkerRolesDto {
  const AssignWorkerRolesDto({required this.roleIds});

  final List<String> roleIds;

  Map<String, dynamic> toJson() => {'roleIds': roleIds};
}
