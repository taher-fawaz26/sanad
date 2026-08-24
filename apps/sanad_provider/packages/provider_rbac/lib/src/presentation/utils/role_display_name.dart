import 'package:easy_localization/easy_localization.dart';
import 'package:provider_rbac/src/domain/entities/role_entity.dart';
import 'package:provider_rbac/src/domain/policies/role_assignment_policy.dart';
import 'package:workers/workers.dart';

/// Localizes a role's display text for the UI.
///
/// **Backend gap:** system roles (`worker-basic`, `branch-manager`) come
/// back from `GET /provider/roles` with a single, backend-fixed
/// `displayName` — there's no `ar`/`en` split on `RoleResponseDto` — so it
/// always reads English regardless of the app's locale. Resolve their label
/// from a local i18n key instead, keyed off the same stable slug
/// [RoleAssignmentPolicy] already treats as the source of truth for "which
/// system role is this". A custom role's `displayName` is free text an
/// admin typed in whatever language they chose, so it passes through
/// unchanged — there's nothing to localize.
extension RoleLocalizedDisplayName on RoleEntity {
  /// This role's display text, localized for a system role.
  String localizedDisplayName() {
    if (!isSystem) return displayName;
    if (name == RoleAssignmentPolicy.baselineSlugFor(WorkerType.worker)) {
      return 'provider_rbac.system_role_worker'.tr();
    }
    if (name == RoleAssignmentPolicy.baselineSlugFor(WorkerType.manager)) {
      return 'provider_rbac.system_role_branch_manager'.tr();
    }
    return displayName;
  }
}
