import 'package:asset_picker/src/domain/entities/asset_picker_options.dart';
import 'package:asset_picker/src/domain/entities/asset_picker_result.dart';
import 'package:asset_picker/src/domain/enums/asset_source.dart';

/// The application-facing contract for acquiring assets.
///
/// This is the abstraction registered through Dependency Injection and
/// resolved by the `AssetPicker` facade. It is deliberately **UI-agnostic**
/// (no `BuildContext`, no widgets) so it lives in the domain layer, is trivial
/// to mock in tests, and can be swapped for a platform-specific or fake
/// implementation without touching any feature code.
///
/// Source selection UI (the bottom sheet) is a presentation concern handled by
/// the facade — this contract only knows how to acquire from a *given* source.
///
/// Every method returns an [AssetPickerResult] (never `null`). User
/// cancellation is a normal result (`AssetPickerResult.cancelled()`); hard
/// failures throw an `AssetPickerException`.
abstract class AssetPickerService {
  /// Acquire assets from an explicit [source], applying [options].
  Future<AssetPickerResult> pickFrom(
    AssetSource source, {
    AssetPickerOptions options = const AssetPickerOptions(),
  });

  /// Capture directly from the camera — no source-selection UI.
  Future<AssetPickerResult> pickCamera({
    AssetPickerOptions options = const AssetPickerOptions(),
  });

  /// Pick directly from the gallery — no source-selection UI.
  Future<AssetPickerResult> pickGallery({
    AssetPickerOptions options = const AssetPickerOptions(),
  });

  /// Pick directly from the file browser — no source-selection UI.
  Future<AssetPickerResult> pickFile({
    AssetPickerOptions options = const AssetPickerOptions(),
  });

  /// Scan a document directly — no source-selection UI.
  Future<AssetPickerResult> scanDocument({
    AssetPickerOptions options = const AssetPickerOptions(),
  });
}
