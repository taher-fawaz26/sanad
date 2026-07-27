import 'package:asset_picker/src/domain/entities/picked_asset.dart';
import 'package:equatable/equatable.dart';

/// The specific rule an asset violated during validation.
enum AssetValidationErrorType {
  /// The asset's extension is not in the allow-list.
  extensionNotAllowed,

  /// The asset's MIME type is not in the allow-list.
  mimeTypeNotAllowed,

  /// The asset's logical type is not in the allow-list.
  assetTypeNotAllowed,

  /// The asset exceeds the configured maximum file size.
  fileTooLarge,

  /// The selection exceeds the configured maximum count.
  tooManyAssets,
}

/// A single, descriptive validation failure for one asset (or the selection
/// as a whole, in the case of [AssetValidationErrorType.tooManyAssets]).
///
/// The [message] is intentionally human-readable and English-default; apps
/// that localise can switch on [type] to produce their own copy.
class AssetValidationError extends Equatable {
  const AssetValidationError({
    required this.type,
    required this.message,
    this.asset,
  });

  /// The rule that was violated.
  final AssetValidationErrorType type;

  /// A descriptive, ready-to-display message.
  final String message;

  /// The offending asset, when the error is asset-scoped. `null` for
  /// selection-scoped errors such as [AssetValidationErrorType.tooManyAssets].
  final PickedAsset? asset;

  @override
  List<Object?> get props => [type, message, asset];

  @override
  String toString() => 'AssetValidationError($type: $message)';
}
