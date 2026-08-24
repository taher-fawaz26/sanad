import 'package:account_settings/src/domain/entities/deletion_blocker.dart';
import 'package:account_settings/src/domain/entities/deletion_warning.dart';
import 'package:account_settings/src/domain/enums/deletion_blocker_code.dart';
import 'package:account_settings/src/domain/enums/deletion_warning_code.dart';
import 'package:easy_localization/easy_localization.dart';

/// Maps blocker/warning codes to localized UI copy — the server's raw code
/// is never shown to the user. An unrecognized code falls back to the
/// server-supplied [DeletionBlocker.message]/[DeletionWarning.message],
/// which is always present.
extension DeletionBlockerLocalizer on DeletionBlocker {
  String localizedMessage() => switch (code) {
    DeletionBlockerCode.alreadyPendingDeletion =>
      'account_deletion.blocker_already_pending'.tr(),
    DeletionBlockerCode.lastActiveSuperAdmin =>
      'account_deletion.blocker_last_active_super_admin'.tr(),
    DeletionBlockerCode.unknown => message,
  };
}

extension DeletionWarningLocalizer on DeletionWarning {
  String localizedMessage() => switch (code) {
    DeletionWarningCode.teamAccountsDeleted =>
      'account_deletion.warning_team_accounts_deleted'.tr(),
    DeletionWarningCode.branchesServicesDeleted =>
      'account_deletion.warning_branches_services_deleted'.tr(),
    DeletionWarningCode.documentsDeleted =>
      'account_deletion.warning_documents_deleted'.tr(),
    DeletionWarningCode.mediaDeleted =>
      'account_deletion.warning_media_deleted'.tr(),
    DeletionWarningCode.employmentLinkLost =>
      'account_deletion.warning_employment_link_lost'.tr(),
    DeletionWarningCode.managedBranchesUnassigned =>
      'account_deletion.warning_managed_branches_unassigned'.tr(),
    DeletionWarningCode.unknown => message,
  };
}
