/// Route path constants for the registration flow.
///
/// All steps are nested under `/signup` and share a single `RegistrationCubit`
/// provided by the flow's `ShellRoute` (see `RegistrationModule`).
abstract final class RegistrationRoutes {
  RegistrationRoutes._();

  static const signUpEmail = '/signup';
  static const selectAccountType = '/signup/account-type';

  /// Organization path — business + representative details.
  static const organizationDetails = '/signup/organization-details';

  /// Individual path — full name.
  static const individualDetails = '/signup/individual-details';

  /// Shared — Emirates ID front/back upload.
  static const identityVerification = '/signup/identity-verification';

  /// Shared — full-screen review of the captured Emirates ID photos.
  static const reviewIdPhotos = '/signup/review-id-photos';

  /// Scan flow — preview of the captured front side before scanning the back.
  static const emiratesIdScanFrontPreview =
      '/signup/emirates-id-scan/front-preview';

  /// Scan flow — preview of the captured back side before the review screen.
  static const emiratesIdScanBackPreview =
      '/signup/emirates-id-scan/back-preview';

  /// Organization only — trade licence upload.
  static const tradeLicence = '/signup/trade-licence';

  /// Shared — full-screen "AI extracting" loading step.
  static const extracting = '/signup/extracting';

  /// Shared — review of the extracted document information.
  static const reviewInformation = '/signup/review';
}
