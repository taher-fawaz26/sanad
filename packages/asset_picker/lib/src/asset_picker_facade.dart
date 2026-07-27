import 'package:asset_picker/src/di/asset_picker_config.dart';
import 'package:asset_picker/src/domain/entities/asset_picker_options.dart';
import 'package:asset_picker/src/domain/entities/asset_picker_result.dart';
import 'package:asset_picker/src/domain/enums/asset_source.dart';
import 'package:asset_picker/src/domain/services/asset_picker_service.dart';
import 'package:asset_picker/src/presentation/sheets/asset_source_sheet.dart';
import 'package:core/core.dart';
import 'package:flutter/widgets.dart';

/// The ergonomic entry point features call to acquire assets.
///
/// [AssetPicker] is a **thin facade, not a utility with logic**: it holds no
/// state and no acquisition code. Every call resolves the DI-registered
/// [AssetPickerService] and delegates to it. That indirection is deliberate —
/// apps register a real, a mock, or a platform-specific service via
/// `AssetPickerDI` / `AssetPickerConfig` and this facade transparently uses it.
///
/// ```dart
/// final result = await AssetPicker.pick(context);          // shows sheet
/// final photo  = await AssetPicker.pickCamera();            // no sheet
/// ```
abstract final class AssetPicker {
  AssetPicker._();

  static AssetPickerService get _service => sl<AssetPickerService>();

  static AssetPickerConfig? get _config =>
      sl.isRegistered<AssetPickerConfig>() ? sl<AssetPickerConfig>() : null;

  static AssetPickerOptions _resolveOptions(AssetPickerOptions? options) =>
      options ?? _config?.defaultOptions ?? const AssetPickerOptions();

  /// Acquire an asset, presenting the design-system source sheet when more than
  /// one source is enabled.
  ///
  /// * With **one** enabled source the sheet is skipped and that source is used
  ///   directly.
  /// * Dismissing the sheet returns [AssetPickerResult.cancelled].
  ///
  /// Throws [ArgumentError] if [options] enables no sources, and an
  /// `AssetPickerException` on permission / validation / platform failure.
  static Future<AssetPickerResult> pick(
    BuildContext context, {
    AssetPickerOptions? options,
  }) async {
    final opts = _resolveOptions(options);
    final sources = _enabledSources(opts);
    if (sources.isEmpty) {
      throw ArgumentError.value(
        opts,
        'options',
        'AssetPickerOptions enables no sources.',
      );
    }

    if (sources.length == 1) {
      return _service.pickFrom(sources.first, options: opts);
    }

    final theme = (_config ?? const AssetPickerConfig()).resolveTheme(context);
    final source = await showAssetSourceSheet(
      context: context,
      options: opts,
      theme: theme,
    );
    if (source == null) return const AssetPickerResult.cancelled();

    return _service.pickFrom(source, options: opts);
  }

  /// Capture from the camera directly — **no** source sheet.
  static Future<AssetPickerResult> pickCamera({
    AssetPickerOptions? options,
  }) => _service.pickCamera(options: _resolveOptions(options));

  /// Pick from the gallery directly — **no** source sheet.
  static Future<AssetPickerResult> pickGallery({
    AssetPickerOptions? options,
  }) => _service.pickGallery(options: _resolveOptions(options));

  /// Pick a file directly — **no** source sheet.
  static Future<AssetPickerResult> pickFile({
    AssetPickerOptions? options,
  }) => _service.pickFile(options: _resolveOptions(options));

  /// Scan a document directly — **no** source sheet.
  static Future<AssetPickerResult> scanDocument({
    AssetPickerOptions? options,
  }) => _service.scanDocument(options: _resolveOptions(options));

  static List<AssetSource> _enabledSources(AssetPickerOptions options) => [
    if (options.allowCamera) AssetSource.camera,
    if (options.allowGallery) AssetSource.gallery,
    if (options.allowFiles) AssetSource.files,
    if (options.allowScanner) AssetSource.scanner,
  ];
}
