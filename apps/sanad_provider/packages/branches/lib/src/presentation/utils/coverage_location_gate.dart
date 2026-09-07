import 'package:maps/maps.dart';

/// Decides whether the Add Branch **Step 2** (coverage) screen must show the
/// location-access blocking body instead of the coverage editor.
///
/// Step 2 configures coverage and discovers serving areas entirely from the
/// canonical location already resolved in Step 1 ([hasResolvedLocation] —
/// place id + coordinates + address) plus map search / tap / pin. It never
/// acquires a fresh device position, so a valid resolved location is
/// sufficient to proceed — the device's live location-services state
/// (GPS master toggle) is irrelevant here.
///
/// Therefore the coverage step is blocked **only** in the live-acquisition
/// fallback: there is no resolved location yet *and* location access is not
/// granted. When a resolved location exists, this returns `false` regardless
/// of permission or services state, which is exactly why disabling device
/// Location while on Step 2 must not surface the "Location services off /
/// Open Settings" screen.
bool isCoverageLocationBlocked({
  required bool hasResolvedLocation,
  required LocationPermissionStatus? permissionStatus,
}) {
  if (hasResolvedLocation) return false;
  return permissionStatus != LocationPermissionStatus.granted;
}
