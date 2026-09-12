import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:maps/maps.dart';

/// The client app's one way to resolve a location.
///
/// Every client feature that needs a place — the AI chat's location capability,
/// the demo journey, and whatever request flow next needs `lat`/`lng` — goes
/// through here, so there is exactly one map experience to fix, localize and
/// test. It is a thin front door on `packages/maps`: the map, the Places
/// search, the reverse geocoding, the permission handling, the camera and the
/// pin all belong to that package and none of them are reimplemented here.
///
/// What this file actually owns is the two things the maps package cannot: the
/// **localized copy**, because `maps` deliberately takes no dependency on
/// `localization` and has its labels injected, and the **client's defaults**.
/// That is the whole reason a caller should never build
/// [LocationPickerLabels] itself — doing so is how two screens in the same app
/// end up with two different translations of "Search for a place", which is
/// exactly the state `branches.location_picker.*` and this section are in
/// today (see the note on [clientLocationPickerLabels]).
///
/// Returns the canonical [LocationPickerResult] — position, address and the
/// Google Place ID when the selection came from search — or `null` when the
/// user backed out without confirming. `null` means *cancelled*: callers must
/// not treat it as a location, and must not advance any flow on it.
Future<LocationPickerResult?> pickClientLocation(
  BuildContext context, {
  LatLng? existingLocation,
  LatLng? initialLocation,
  String? initialAddress,
  String? initialPlaceId,
  String? title,
  String? subtitle,
  bool requirePlaceId = false,
}) => showLocationPickerSheet(
  context,
  labels: clientLocationPickerLabels(title: title, subtitle: subtitle),
  existingLocation: existingLocation,
  initialLocation: initialLocation,
  initialAddress: initialAddress,
  initialPlaceId: initialPlaceId,
  // Off by default: a client asking "where is the job?" is answered perfectly
  // well by a dropped pin or the device position, and demanding a Place ID
  // would reject both. The provider's branch flow sets it because its backend
  // stores a Place ID; a client caller with the same constraint can opt in.
  requirePlaceId: requirePlaceId,
);

/// The client's localized labels for the shared picker.
///
/// Separate from [pickClientLocation] so a caller that embeds
/// `MapLocationPicker` directly — rather than as a sheet — still gets the same
/// copy instead of retyping eighteen keys.
///
/// The strings live under a top-level `location_picker.*` section rather than
/// under a feature, because they describe the *map*, not the caller. The
/// provider's `branches.location_picker.*` block says the same things in its
/// own keys; consolidating the two is a safe follow-up, deliberately not done
/// here because it would touch a provider flow this change has no reason to
/// risk.
LocationPickerLabels clientLocationPickerLabels({
  String? title,
  String? subtitle,
}) => LocationPickerLabels(
  title: title ?? 'location_picker.title'.tr(),
  subtitle: subtitle ?? 'location_picker.subtitle'.tr(),
  searchHint: 'location_picker.search_hint'.tr(),
  confirm: 'common.confirm'.tr(),
  specifiedLocation: 'location_picker.specified_location'.tr(),
  addressHint: 'location_picker.address_hint'.tr(),
  permissionDenied: 'location_picker.permission_denied'.tr(),
  permissionPermanentlyDenied: 'location_picker.permission_permanently_denied'
      .tr(),
  serviceDisabled: 'location_picker.service_disabled'.tr(),
  genericError: 'location_picker.generic_error'.tr(),
  openSettings: 'common.open_settings'.tr(),
  openLocationSettings: 'location_picker.open_location_settings'.tr(),
  retry: 'common.retry'.tr(),
  locationUnavailable: 'location_picker.location_unavailable'.tr(),
  locationTimeout: 'location_picker.location_timeout'.tr(),
  addressNotFound: 'location_picker.address_not_found'.tr(),
  searchEmpty: 'location_picker.no_results'.tr(),
  searchRetry: 'common.retry'.tr(),
  outsideCountry: 'location_picker.outside_uae'.tr(),
);
