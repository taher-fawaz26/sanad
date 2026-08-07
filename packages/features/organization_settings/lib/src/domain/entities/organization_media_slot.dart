/// Which organization identity image a media operation targets.
enum OrganizationMediaSlot {
  cover,
  logo
  ;

  /// The `PATCH` endpoint that applies an uploaded `mediaId` to this slot.
  ///
  /// Matches the documented two-step contract: `POST media/upload-single`
  /// returns a `mediaId`, then this endpoint is PATCHed with `{mediaId}`.
  String get endpoint => switch (this) {
    OrganizationMediaSlot.cover => 'service-provider/cover-image',
    OrganizationMediaSlot.logo => 'service-provider/profile-image',
  };
}
