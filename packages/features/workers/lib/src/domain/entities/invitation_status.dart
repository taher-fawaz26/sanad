enum InvitationStatus {
  pending,
  accepted,
  expired
  ;

  static InvitationStatus fromString(String? value) =>
      switch (value?.toLowerCase()) {
        'pending' => InvitationStatus.pending,
        'accepted' => InvitationStatus.accepted,
        'expired' => InvitationStatus.expired,
        _ => InvitationStatus.pending,
      };
}
