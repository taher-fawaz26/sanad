import 'package:provider_rbac/src/domain/entities/role_entity.dart';
import 'package:workers/workers.dart';

/// Centralizes the mapping between a member's [WorkerType] and the baseline
/// system role their invitation must always carry.
///
/// **Backend gap:** `GET /provider/roles` carries no machine-readable
/// "default role for this type" signal — every role currently returns
/// `userType: worker` (there is no `userType: manager`), and there is no
/// `isDefault` / `defaultForType` flag on `RoleResponseDto`. The only stable
/// discriminator is the system role's `name` slug. This policy isolates that
/// slug lookup in one place rather than scattering display-name string
/// matching through the UI. `POST /workers/invitations`'s `roleIds` field
/// documents the same mapping in prose ("the baseline system role for the
/// type — worker or branch manager — is added on top automatically") and the
/// backend re-applies it server-side, so a stale slug here degrades to a
/// missing *client-side* lock rather than a missing role. Recommendation: add
/// `isDefault`/`defaultForType` metadata (or a `userType: manager` system
/// role) to `RoleResponseDto` so this can switch from a name slug to an
/// explicit flag.
abstract final class RoleAssignmentPolicy {
  /// The system role `name` slug that is mandatory for [type].
  static String baselineSlugFor(WorkerType type) => switch (type) {
    WorkerType.worker => 'worker-basic',
    WorkerType.manager => 'branch-manager',
  };

  /// The mandatory system role for [type] within [catalog], or `null` if the
  /// backend catalog does not (yet) contain it.
  static RoleEntity? requiredRoleFor(
    WorkerType type,
    List<RoleEntity> catalog,
  ) {
    final slug = baselineSlugFor(type);
    for (final role in catalog) {
      if (role.isSystem && role.name == slug) return role;
    }
    return null;
  }

  /// Whether [role] is the mandatory baseline role for [type].
  static bool isMandatory(RoleEntity role, WorkerType type) =>
      role.isSystem && role.name == baselineSlugFor(type);

  /// Whether [role] may be removed from the selection for [type]. The
  /// mandatory baseline can never be removed; every other role can.
  static bool canRemove(RoleEntity role, WorkerType type) =>
      !isMandatory(role, type);

  /// Roles a user may add on top of the mandatory baseline.
  ///
  /// A worker's role set is exactly `[worker-basic]` — no customization — so
  /// [WorkerType.worker] never has additional roles to offer. A manager may
  /// add any custom role (`!isSystem`); system roles are always excluded,
  /// since both the *other* type's baseline and this type's own baseline are
  /// already locked in, not offered as a pick.
  static List<RoleEntity> assignableAdditionalRoles(
    WorkerType type,
    List<RoleEntity> catalog,
  ) {
    if (type == WorkerType.worker) return const [];
    return catalog.where((role) => !role.isSystem).toList();
  }

  /// Rebuilds the selected-role set after [type] changes.
  ///
  /// Worker has no customization: the result is exactly the mandatory
  /// baseline (`[worker-basic]`), discarding every other previously-selected
  /// role, including custom ones. Manager keeps every valid custom role from
  /// [selected] on top of its mandatory baseline (`branch-manager`),
  /// dropping any system role (including a stray `worker-basic`) and
  /// de-duplicating by id.
  static List<RoleEntity> normalizeAfterTypeChange(
    WorkerType type,
    List<RoleEntity> selected,
    List<RoleEntity> catalog,
  ) {
    final required = requiredRoleFor(type, catalog);

    if (type == WorkerType.worker) {
      return required == null ? const [] : [required];
    }

    final result = <String, RoleEntity>{};
    if (required != null) result[required.id] = required;
    for (final role in selected) {
      // System roles are always type-bound baselines — only the freshly
      // resolved [required] baseline (added above) may occupy that slot.
      if (role.isSystem) continue;
      result[role.id] = role;
    }
    return result.values.toList();
  }
}
