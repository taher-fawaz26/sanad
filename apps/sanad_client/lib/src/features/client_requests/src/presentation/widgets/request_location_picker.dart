import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:maps/maps.dart';

/// Opens the shared map picker to choose where the work is.
///
/// The label set is reused from `branches.location_picker.*` rather than
/// duplicated under a client namespace: every string in it describes the map
/// and the OS permission states, none of it is branch-specific, and one copy
/// means a wording fix lands in both apps. Only the header, which *is*
/// context-specific, is overridden.
///
/// Returns `null` when the sheet is dismissed without confirming.
Future<LocationPickerResult?> pickRequestLocation(
  BuildContext context, {
  double? lat,
  double? lng,
  String? address,
}) {
  final existing = (lat != null && lng != null) ? LatLng(lat, lng) : null;
  return showLocationPickerSheet(
    context,
    existingLocation: existing,
    initialAddress: address,
    labels: LocationPickerLabels(
      title: 'client_requests.location_label'.tr(),
      subtitle: 'client_requests.location_placeholder'.tr(),
      searchHint: 'branches.location_picker.search_hint'.tr(),
      confirm: 'common.confirm'.tr(),
      specifiedLocation: 'branches.location_picker.specified_location'.tr(),
      addressHint: 'branches.location_picker.address_hint'.tr(),
      permissionDenied: 'branches.location_picker.permission_denied'.tr(),
      permissionPermanentlyDenied:
          'branches.location_picker.permission_permanently_denied'.tr(),
      serviceDisabled: 'branches.location_picker.service_disabled'.tr(),
      genericError: 'branches.location_picker.generic_error'.tr(),
      openSettings: 'branches.location_picker.open_settings'.tr(),
      openLocationSettings: 'branches.location_picker.open_location_settings'
          .tr(),
      retry: 'common.retry'.tr(),
      locationUnavailable: 'branches.location_picker.location_unavailable'.tr(),
      locationTimeout: 'branches.location_picker.location_timeout'.tr(),
      addressNotFound: 'branches.location_picker.address_not_found'.tr(),
      searchEmpty: 'branches.location_picker.no_results'.tr(),
      searchRetry: 'common.retry'.tr(),
      outsideCountry: 'branches.location_picker.outside_uae'.tr(),
    ),
  );
}
