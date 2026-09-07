/// Stable action discriminators for `GET /activity-logs` — switch UI
/// behavior on this, never on the server-localized `name`.
///
/// Enum member names match the backend's API values exactly (verified
/// against the live Swagger contract), so [fromApiValue] is a straight
/// name lookup rather than a hand-maintained switch. [unknown] is the
/// forward-compat fallback for any action the backend adds after this
/// client ships — it must never throw or break rendering.
enum ActivityAction {
  branchCreated,
  branchUpdated,
  branchStatusChanged,
  branchDeleted,
  workerInvitationSent,
  workerInvitationResent,
  workerInvitationCancelled,
  workerInvitationDeleted,
  workerInvitationAccepted,
  workerUpdated,
  workerStatusChanged,
  workerDeleted,
  workerRolesAssigned,
  workerRoleRemoved,
  providerServiceAdded,
  providerServiceUpdated,
  providerServiceStatusChanged,
  providerServiceImagesUpdated,
  providerServiceRemoved,
  providerServiceModerated,
  serviceRequestSubmitted,
  serviceRequestUpdated,
  serviceRequestApproved,
  serviceRequestRejected,
  providerRoleCreated,
  providerRoleUpdated,
  providerRoleDeleted,
  providerApplicationSubmitted,
  businessSettingsUpdated,
  accountSettingsUpdated,
  workingHoursUpdated,
  profileImageUpdated,
  coverImageUpdated,
  legalDocumentsUpdated,
  businessEmailChanged,
  businessPhoneChanged,
  ownerEmailChanged,
  ownerPhoneChanged,
  documentVerified,
  documentRejected,
  documentChangesRequested,
  documentExpiringSoon,
  documentExpired,
  applicationApproved,
  applicationRejected,
  accountSuspended,
  accountReactivated,
  accountUpdatedByAdmin,
  accountDeletedByAdmin,
  accountRestoredByAdmin,
  accountDeletionRequested,
  accountDeletionCancelled,
  accountDeletionExecuted,
  unknown
  ;

  static ActivityAction fromApiValue(String? value) => ActivityAction.values
      .firstWhere((action) => action.name == value, orElse: () => unknown);
}
