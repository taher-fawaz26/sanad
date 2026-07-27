import 'package:asset_picker/src/domain/entities/picked_asset.dart';
import 'package:asset_picker/src/domain/enums/asset_source.dart';
import 'package:equatable/equatable.dart';

/// The outcome of a pick operation.
///
/// A result is always returned (the API never returns `null`): callers inspect
/// [cancelled] and [assets] rather than doing null checks. Hard errors
/// (permission denied, validation failure, platform errors) are surfaced as an
/// `AssetPickerException` thrown from the service instead.
class AssetPickerResult extends Equatable {
  const AssetPickerResult({
    required this.assets,
    required this.source,
    required this.cancelled,
  });

  /// A successful pick from [source] yielding [assets].
  const AssetPickerResult.success({
    required List<PickedAsset> assets,
    required AssetSource source,
  }) : this(assets: assets, source: source, cancelled: false);

  /// The user dismissed the picker without choosing anything.
  const AssetPickerResult.cancelled()
    : this(assets: const [], source: null, cancelled: true);

  /// The assets the user selected. Empty when [cancelled].
  final List<PickedAsset> assets;

  /// The source the assets were acquired from. `null` when [cancelled].
  final AssetSource? source;

  /// Whether the operation was cancelled by the user.
  final bool cancelled;

  /// Whether the operation produced at least one asset.
  bool get hasAssets => assets.isNotEmpty;

  /// Whether the operation produced no assets (cancelled or empty selection).
  bool get isEmpty => assets.isEmpty;

  /// The first (or only) asset, or `null` when [isEmpty].
  PickedAsset? get single => assets.isEmpty ? null : assets.first;

  @override
  List<Object?> get props => [assets, source, cancelled];

  @override
  String toString() =>
      'AssetPickerResult(cancelled: $cancelled, source: $source, '
      'count: ${assets.length})';
}
