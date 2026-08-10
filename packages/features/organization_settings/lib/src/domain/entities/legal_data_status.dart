/// Expiry state of a legal document (Emirates ID / trade licence) —
/// `NationalIdResponseDto.status` / `TradeLicenseResponseDto.status`.
///
/// Replaces the old `isExpired`/`isExpiringSoon` booleans. Recomputed by the
/// backend from `expiryDate` on every read, so it is never stale.
enum LegalDataStatus {
  /// Not expired and not close to expiring.
  verified,

  /// Still valid, but close enough to expiry to warn the user.
  expiringSoon,

  /// Past its expiry date.
  expired
  ;

  factory LegalDataStatus.fromJson(String value) => switch (value) {
    'verified' => LegalDataStatus.verified,
    'expiring_soon' => LegalDataStatus.expiringSoon,
    'expired' => LegalDataStatus.expired,
    _ => throw ArgumentError('Unknown LegalDataStatus: $value'),
  };
}
