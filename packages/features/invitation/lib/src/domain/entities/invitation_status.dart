/// Mirrors `VerifyInvitationTokenResponseDto.status` — present only when the
/// invitation is no longer actionable (`valid: false`).
enum InvitationStatus {
  pending,
  accepted,
  expired,
  cancelled
  ;

  static InvitationStatus fromString(String value) =>
      InvitationStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => throw ArgumentError('Unknown InvitationStatus: $value'),
      );
}
