import 'package:asset_picker/asset_picker.dart' show AssetSource;

export 'package:asset_picker/asset_picker.dart' show AssetSource;

/// The acquisition source of a piece of media.
///
/// Aliased to `asset_picker`'s [AssetSource] so the picking layer stays the
/// single source of truth for source enumeration; callers of `media` need not
/// import `asset_picker` directly. The underlying enum is re-exported above so
/// its members (`AssetSource.camera`, …) are reachable through this library.
typedef MediaSource = AssetSource;
