/// Identifies the persona of an authenticated account.
///
/// [value] is the exact string the live API uses on the wire — in
/// `POST /auth/profile` (`CreateProviderProfileDto.userType`,
/// `individualProvider | organizationProvider` only) and in every response
/// that carries a `userType` field (`AuthUserResponseDto`, `MeResponseDto`:
/// the full six-value set below). [fromString] normalizes case-insensitively
/// and also accepts the retired wire value `companyProvider` (pre-rename),
/// so a session cached by an older build still deserializes instead of
/// crashing the splash screen.
enum UserType {
  individualProvider('individualProvider'),
  organizationProvider('organizationProvider'),
  client('client'),
  worker('worker'),
  manager('manager'),
  admin('admin')
  ;

  const UserType(this.value);

  final String value;

  static UserType fromString(String value) {
    final normalized = value.trim().toUpperCase();
    // Pre-rename wire/cache value — see class doc.
    if (normalized == 'COMPANYPROVIDER') return UserType.organizationProvider;
    return UserType.values.firstWhere(
      (type) => type.value.toUpperCase() == normalized,
      orElse: () => throw ArgumentError(
        'Unknown UserType wire value: "$value". '
        'Expected one of '
        '${UserType.values.map((e) => e.value.toUpperCase()).toList()} '
        '(case-insensitive, plus the legacy alias "companyProvider").',
      ),
    );
  }

  static UserType fromJson(String value) {
    return UserType.fromString(value);
  }

  static String toJson(UserType value) {
    return value.value;
  }
}
