/// `DeletionBlockerDto.code` — machine-readable blocker identifiers.
///
/// [unknown] carries the raw server code so the UI can fail safe (show the
/// server message, never crash or invent business logic) for a code the
/// client doesn't yet recognize.
enum DeletionBlockerCode {
  alreadyPendingDeletion,
  lastActiveSuperAdmin,
  unknown
  ;

  static DeletionBlockerCode fromApi(String value) => switch (value) {
    'ALREADY_PENDING_DELETION' => DeletionBlockerCode.alreadyPendingDeletion,
    'LAST_ACTIVE_SUPER_ADMIN' => DeletionBlockerCode.lastActiveSuperAdmin,
    _ => DeletionBlockerCode.unknown,
  };
}
