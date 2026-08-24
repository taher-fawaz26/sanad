/// `AccountDeletionResponseDto.status` — lifecycle state of a deletion
/// request.
enum AccountDeletionStatus {
  pendingVerification,
  scheduled,
  executing,
  completed,
  cancelled,
  failed,
  restored,
  unknown
  ;

  static AccountDeletionStatus fromApi(String value) => switch (value) {
    'pending_verification' => AccountDeletionStatus.pendingVerification,
    'scheduled' => AccountDeletionStatus.scheduled,
    'executing' => AccountDeletionStatus.executing,
    'completed' => AccountDeletionStatus.completed,
    'cancelled' => AccountDeletionStatus.cancelled,
    'failed' => AccountDeletionStatus.failed,
    'restored' => AccountDeletionStatus.restored,
    _ => AccountDeletionStatus.unknown,
  };
}

/// `AccountDeletionResponseDto.initiator`.
enum DeletionInitiator {
  self,
  admin,
  unknown
  ;

  static DeletionInitiator fromApi(String value) => switch (value) {
    'self' => DeletionInitiator.self,
    'admin' => DeletionInitiator.admin,
    _ => DeletionInitiator.unknown,
  };
}
