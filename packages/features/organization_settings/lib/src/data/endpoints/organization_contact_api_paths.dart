/// Backend endpoints for organization contact info (phone/email).
///
/// TODO(endpoint): confirm these paths with the backend once the
/// organization contact request/verify/refresh endpoints are finalized in the
/// API spec.
abstract final class OrganizationContactApiPaths {
  OrganizationContactApiPaths._();

  static const String contact = 'organizations/me/contact';
  static const String phoneRequestOtp = 'organizations/me/phone/request-otp';
  static const String phoneVerify = 'organizations/me/phone/verify';
  static const String emailRequestOtp = 'organizations/me/email/request-otp';
  static const String emailVerify = 'organizations/me/email/verify';
}
