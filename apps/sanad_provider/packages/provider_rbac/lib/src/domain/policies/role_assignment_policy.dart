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

  /// Roles a user may add on top of the mandatory baseline: custom roles
  /// only. System roles are type-bound — the *other* type's system role must
  /// never be offered as an additional pick, since that would let it silently
  /// replace the mandatory baseline.
  static List<RoleEntity> assignableAdditionalRoles(
    List<RoleEntity> catalog,
  ) => catalog.where((role) => !role.isSystem).toList();

  /// System baseline slugs for every [WorkerType] — used to strip *any*
  /// previous type's baseline out of a selection, regardless of which type
  /// it came from.
  static final Set<String> _baselineSlugs = WorkerType.values
      .map(baselineSlugFor)
      .toSet();

  /// Rebuilds the selected-role set after [type] changes: drops the previous
  /// type's baseline, adds the new type's baseline, preserves every
  /// additional role the user already picked, and de-duplicates by id.
  static List<RoleEntity> normalizeAfterTypeChange(
    WorkerType type,
    List<RoleEntity> selected,
    List<RoleEntity> catalog,
  ) {
    final required = requiredRoleFor(type, catalog);

    final result = <String, RoleEntity>{};
    if (required != null) result[required.id] = required;
    for (final role in selected) {
      // System defaults are type-bound and never survive a type change —
      // only the freshly resolved [required] baseline (added above) may
      // occupy that slot.
      if (role.isSystem && _baselineSlugs.contains(role.name)) continue;
      result[role.id] = role;
    }
    return result.values.toList();
  }
}
