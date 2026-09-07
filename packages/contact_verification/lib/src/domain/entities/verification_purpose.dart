/// What a contact-verification session unlocks.
///
/// This is the single `purpose` enum shared by the whole backend contract
/// (`/contact-verification/{request,resend,verify,resend-info}`) — the same
/// four endpoints serve both the signed-in owner's contact details and the
/// organization's business contact details; only the purpose differs.
enum VerificationPurpose {
  changeOwnerEmail,
  changeOwnerPhone,
  changeBusinessEmail,
  changeBusinessPhone
  ;

  /// The wire value the backend expects/returns (snake_case).
  String toApi() => switch (this) {
    VerificationPurpose.changeOwnerEmail => 'change_owner_email',
    VerificationPurpose.changeOwnerPhone => 'change_owner_phone',
    VerificationPurpose.changeBusinessEmail => 'change_business_email',
    VerificationPurpose.changeBusinessPhone => 'change_business_phone',
  };

  /// Parses a wire value, or `null` when it is absent or unrecognized.
  ///
  /// Preferred wherever a bad value should not take down a flow that has
  /// otherwise succeeded — see [fromApi] for the strict form.
  static VerificationPurpose? tryFromApi(Object? value) => switch (value) {
    'change_owner_email' => VerificationPurpose.changeOwnerEmail,
    'change_owner_phone' => VerificationPurpose.changeOwnerPhone,
    'change_business_email' => VerificationPurpose.changeBusinessEmail,
    'change_business_phone' => VerificationPurpose.changeBusinessPhone,
    _ => null,
  };

  static VerificationPurpose fromApi(String value) => switch (value) {
    'change_owner_email' => VerificationPurpose.changeOwnerEmail,
    'change_owner_phone' => VerificationPurpose.changeOwnerPhone,
    'change_business_email' => VerificationPurpose.changeBusinessEmail,
    'change_business_phone' => VerificationPurpose.changeBusinessPhone,
    _ => throw ArgumentError.value(
      value,
      'value',
      'Unknown VerificationPurpose',
    ),
  };

  /// Whether the code is delivered by email or SMS — the backend derives the
  /// channel from the purpose, so there is no separate channel parameter.
  bool get isEmail =>
      this == VerificationPurpose.changeOwnerEmail ||
      this == VerificationPurpose.changeBusinessEmail;

  bool get isPhone => !isEmail;

  /// Whether this purpose changes the signed-in owner's own contact details
  /// (vs. the organization's business contact details).
  bool get isOwner =>
      this == VerificationPurpose.changeOwnerEmail ||
      this == VerificationPurpose.changeOwnerPhone;
}
