enum InvitationStatus {
  pending,
  accepted,
  expired,
  cancelled
  ;

  static InvitationStatus fromString(String? value) =>
      switch (value?.toLowerCase()) {
        'pending' => InvitationStatus.pending,
        'accepted' => InvitationStatus.accepted,
        'expired' => InvitationStatus.expired,
        'cancelled' => InvitationStatus.cancelled,
        _ => InvitationStatus.pending,
      };
}
