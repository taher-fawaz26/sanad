/// Route path constants for the registration flow.
///
/// All steps are nested under `/signup` and share a single
/// `RegistrationDetailsCubit` + `DocumentFlowBloc` pair provided by the
/// flow's `ShellRoute` (see `RegistrationModule`).
abstract final class RegistrationRoutes {
  RegistrationRoutes._();

  static const selectAccountType = '/signup/account-type';

  /// Organization path — business name details.
  static const organizationDetails = '/signup/organization-details';

  /// Individual path — full name.
  static const individualDetails = '/signup/individual-details';

  /// Shared — Emirates ID identity verification landing + capture flow.
  static const identityVerification = '/signup/identity-verification';

  /// Shared — two-sided Emirates ID repair (front + back), pushed from
  /// Review Information when an issue's `DocumentRepairTarget` requires the
  /// whole document replaced together (e.g. a front/back mismatch), rather
  /// than the default single-file replace.
  static const repairEmiratesId = '/signup/repair-emirates-id';

  /// Organization only — trade licence upload.
  static const tradeLicence = '/signup/trade-licence';

  /// Shared — full-screen "AI extracting" loading step.
  static const extracting = '/signup/extracting';

  /// Shared — review of the extracted document information.
  static const reviewInformation = '/signup/review';
}
