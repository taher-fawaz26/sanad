/// Where an asset is acquired from.
///
/// A source maps 1:1 to an abstract provider (`CameraProvider`,
/// `GalleryProvider`, `FileProvider`, `ScannerProvider`). Adding a new source
/// (e.g. cloud storage, clipboard) is an additive change: extend this enum and
/// register a provider for it — no existing call site breaks.
enum AssetSource {
  /// Capture a fresh photo with the device camera.
  camera,

  /// Choose an existing item from the photo gallery.
  gallery,

  /// Browse the device / cloud file system.
  files,

  /// Scan a physical document (edge detection, perspective correction).
  scanner
  ;

  /// A stable, machine-readable key (useful for analytics / logging).
  String get key => name;
}
