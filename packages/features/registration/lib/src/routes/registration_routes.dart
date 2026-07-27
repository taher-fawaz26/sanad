/// Route path constants for the registration flow.
abstract final class RegistrationRoutes {
  RegistrationRoutes._();

  static const signUpEmail = '/signup';

  /// Relative: `otp` → full: `/signup/otp`
  static const signUpOtp = '/signup/otp';

  /// Relative: `account-type` → full: `/signup/account-type`
  static const selectAccountType = '/signup/account-type';

  /// Relative: `organization-details` → full: `/signup/organization-details`
  static const organizationDetails = '/signup/organization-details';

  /// Relative: `identity-verification` → full: `/signup/identity-verification`
  static const identityVerification = '/signup/identity-verification';

  /// Relative: `scan-emirates-id-front` → full: `/signup/scan-emirates-id-front`
  static const scanEmiratesIdFront = '/signup/scan-emirates-id-front';

  /// Relative: `capture-preview-front` → full: `/signup/capture-preview-front`
  static const capturePreviewFront = '/signup/capture-preview-front';
}
