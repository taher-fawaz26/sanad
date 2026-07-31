/// API path constants for media upload endpoints.
abstract final class MediaApiPaths {
  MediaApiPaths._();

  /// `POST media/onboarding` — onboarding multipart upload (field: `file`).
  ///
  /// Relative to the `/api/v1/` base URL. Uses the onboarding Bearer token.
  static const onboarding = 'media/onboarding';

  /// `POST auth/extract` — extract document data from uploaded media IDs.
  ///
  /// Body: `{ emiratesIdFrontId, emiratesIdBackId, tradeLicenseId? }`.
  /// Uses the onboarding Bearer token.
  static const extract = 'auth/extract';

  /// `POST auth/profile/individual-provider` — complete profile for individual.
  ///
  /// Body: `{ emiratesIdFrontId, emiratesIdBackId, fullName }`.
  /// Uses the onboarding Bearer token.
  static const individualProvider = 'auth/profile/individual-provider';

  /// `POST auth/profile/company-provider` — complete profile for organization.
  ///
  /// Body: `{ emiratesIdFrontId, emiratesIdBackId, tradeLicenseId, businessName, representativeFullName, representativeEmail }`.
  /// Uses the onboarding Bearer token.
  static const companyProvider = 'auth/profile/company-provider';
}
