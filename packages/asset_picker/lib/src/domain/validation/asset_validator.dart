import 'package:asset_picker/src/domain/entities/asset_picker_options.dart';
import 'package:asset_picker/src/domain/entities/picked_asset.dart';
import 'package:asset_picker/src/domain/enums/asset_type.dart';
import 'package:asset_picker/src/domain/validation/asset_validation_error.dart';
import 'package:core/core.dart';

/// Validates a selection of [PickedAsset]s against [AssetPickerOptions].
///
/// A pure, stateless, dependency-free component (no Flutter, no plugins) so it
/// is trivially unit-testable and reusable. The default implementation is
/// [DefaultAssetValidator]; apps may register their own to enforce extra
/// business rules without touching the picker pipeline.
abstract class AssetValidator {
  /// Returns every rule violation found in [assets] under [options]. An empty
  /// list means the selection is valid.
  List<AssetValidationError> validate(
    List<PickedAsset> assets,
    AssetPickerOptions options,
  );
}

/// The built-in [AssetValidator] enforcing count, size, extension, MIME, and
/// asset-type constraints described by [AssetPickerOptions].
class DefaultAssetValidator implements AssetValidator {
  const DefaultAssetValidator();

  @override
  List<AssetValidationError> validate(
    List<PickedAsset> assets,
    AssetPickerOptions options,
  ) {
    final errors = <AssetValidationError>[];

    // ── Count ────────────────────────────────────────────────────────────
    final max = options.effectiveMaxSelection;
    if (assets.length > max) {
      errors.add(
        AssetValidationError(
          type: AssetValidationErrorType.tooManyAssets,
          message:
              'You can select at most $max '
              '${max == 1 ? 'item' : 'items'} '
              '(selected ${assets.length}).',
        ),
      );
    }

    final allowedExtensions = options.resolvedAllowedExtensions;
    final allowedMimeTypes = options.allowedMimeTypes
        ?.map((m) => m.toLowerCase())
        .toSet();
    final allowedTypes = options.allowedAssetTypes
        ?.where((t) => t != AssetType.any)
        .toSet();

    for (final asset in assets) {
      // ── Size ─────────────────────────────────────────────────────────
      // Never trusts `options.maxFileSize` alone — clamped against the
      // global `FileSizePolicy` so no call site (present or future) can
      // accept a file larger than the app-wide maximum, whether it forgets
      // to set a limit at all or explicitly requests a looser one. A
      // caller may still request a *stricter* (smaller) limit.
      final maxSize = FileSizePolicy.effectiveLimit(options.maxFileSize);
      if (asset.size > maxSize) {
        errors.add(
          AssetValidationError(
            type: AssetValidationErrorType.fileTooLarge,
            asset: asset,
            message:
                '"${asset.name}" is ${_formatBytes(asset.size)}, which '
                'exceeds the ${_formatBytes(maxSize)} limit.',
          ),
        );
      }

      // ── Extension ──────────────────────────────────────────────────────
      if (allowedExtensions != null &&
          allowedExtensions.isNotEmpty &&
          !allowedExtensions.contains(asset.extension)) {
        errors.add(
          AssetValidationError(
            type: AssetValidationErrorType.extensionNotAllowed,
            asset: asset,
            message:
                '"${asset.name}" has an unsupported type. Allowed: '
                '${allowedExtensions.join(', ')}.',
          ),
        );
      }

      // ── MIME ───────────────────────────────────────────────────────────
      if (allowedMimeTypes != null &&
          allowedMimeTypes.isNotEmpty &&
          !allowedMimeTypes.contains(asset.mimeType.toLowerCase())) {
        errors.add(
          AssetValidationError(
            type: AssetValidationErrorType.mimeTypeNotAllowed,
            asset: asset,
            message:
                '"${asset.name}" (${asset.mimeType}) is not an accepted '
                'format.',
          ),
        );
      }

      // ── Asset type ─────────────────────────────────────────────────────
      if (allowedTypes != null &&
          allowedTypes.isNotEmpty &&
          !allowedTypes.contains(asset.assetType)) {
        errors.add(
          AssetValidationError(
            type: AssetValidationErrorType.assetTypeNotAllowed,
            asset: asset,
            message:
                '"${asset.name}" is not one of the accepted kinds: '
                '${allowedTypes.map((t) => t.name).join(', ')}.',
          ),
        );
      }
    }

    return errors;
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }
}
