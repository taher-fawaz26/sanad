/// `DeletionWarningDto.code` — machine-readable warning identifiers.
///
/// [unknown] carries the raw server code so the UI can fail safe (show the
/// server message, never crash or invent business logic) for a code the
/// client doesn't yet recognize.
enum DeletionWarningCode {
  teamAccountsDeleted,
  branchesServicesDeleted,
  documentsDeleted,
  mediaDeleted,
  employmentLinkLost,
  managedBranchesUnassigned,
  unknown
  ;

  static DeletionWarningCode fromApi(String value) => switch (value) {
    'TEAM_ACCOUNTS_DELETED' => DeletionWarningCode.teamAccountsDeleted,
    'BRANCHES_SERVICES_DELETED' => DeletionWarningCode.branchesServicesDeleted,
    'DOCUMENTS_DELETED' => DeletionWarningCode.documentsDeleted,
    'MEDIA_DELETED' => DeletionWarningCode.mediaDeleted,
    'EMPLOYMENT_LINK_LOST' => DeletionWarningCode.employmentLinkLost,
    'MANAGED_BRANCHES_UNASSIGNED' =>
      DeletionWarningCode.managedBranchesUnassigned,
    _ => DeletionWarningCode.unknown,
  };
}
