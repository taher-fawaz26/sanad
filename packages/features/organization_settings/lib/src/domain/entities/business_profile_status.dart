/// The business profile's review/lifecycle status — `MeBusinessProfileDto
/// .status`.
///
/// Replaces the old boolean `isReviewed`: a rejected provider still reads
/// [inReview] (distinguished by a non-null `rejectionReason`), and
/// [expired]/[suspended] are states a provider needs to act on, distinct
/// from simply "not yet reviewed".
enum BusinessProfileStatus {
  /// Submitted and awaiting backend review (or rejected — see
  /// `rejectionReason`).
  inReview,

  /// Reviewed and live to customers.
  active,

  /// Was active; has lapsed (e.g. an expired trade license) and needs
  /// renewal.
  expired,

  /// Suspended by the backend/admin.
  suspended
  ;

  factory BusinessProfileStatus.fromJson(String value) => switch (value) {
    'INREVIEW' => BusinessProfileStatus.inReview,
    'ACTIVE' => BusinessProfileStatus.active,
    'EXPIRED' => BusinessProfileStatus.expired,
    'SUSPENDED' => BusinessProfileStatus.suspended,
    _ => throw ArgumentError('Unknown BusinessProfileStatus: $value'),
  };
}
