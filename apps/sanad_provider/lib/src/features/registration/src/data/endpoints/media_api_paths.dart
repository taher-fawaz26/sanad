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

  /// `POST auth/profile` — complete provider profile
  /// (`CreateProviderProfileDto`).
  ///
  /// Body: `{ emiratesIdFrontId, emiratesIdBackId, userType,
  /// fullName? (individualProvider), businessName?, representativeFullName?,
  /// tradeLicenseId? (organizationProvider) }`.
  /// Uses the onboarding Bearer token.
  static const profile = 'auth/profile';
}
