import 'package:organization_settings/src/data/endpoints/organization_media_api_paths.dart';

/// Which organization identity image a media operation targets.
enum OrganizationMediaSlot {
  cover,
  logo;

  /// The upload/remove endpoint for this slot.
  String get endpoint => switch (this) {
    OrganizationMediaSlot.cover => OrganizationMediaApiPaths.cover,
    OrganizationMediaSlot.logo => OrganizationMediaApiPaths.logo,
  };
}
