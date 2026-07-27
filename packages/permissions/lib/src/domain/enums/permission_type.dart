/// Strongly-typed identifiers for every permission the monorepo may request.
///
/// Platform notes:
/// - [gallery]: Android → READ_EXTERNAL_STORAGE / READ_MEDIA_IMAGES (API 33+);
///   iOS → Photos library (same as [photos]).
/// - [storage]: Android only — READ/WRITE_EXTERNAL_STORAGE; no-op on iOS.
/// - [manageExternalStorage]: Android 11+ MANAGE_EXTERNAL_STORAGE only.
/// - [mediaLibrary]: iOS Apple Music / media library only; no-op on Android.
/// - [nearbyDevices]: Android → NEARBY_WIFI_DEVICES; iOS → Bluetooth.
/// - [notifications]: iOS may return [PermissionStatus.provisional] on first
///   launch before the user is explicitly prompted.
/// - [locationAlways]: requires [locationWhenInUse] to be granted first on iOS.
enum PermissionType {
  camera,
  photos,
  gallery,
  storage,
  documents,
  microphone,
  locationWhenInUse,
  locationAlways,
  notifications,
  contacts,
  calendar,
  bluetooth,
  nearbyDevices,
  phone,
  mediaLibrary,
  manageExternalStorage,
}
