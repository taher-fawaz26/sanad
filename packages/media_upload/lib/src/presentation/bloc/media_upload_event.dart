part of 'media_upload_bloc.dart';

sealed class MediaUploadEvent extends Equatable {
  const MediaUploadEvent();

  @override
  List<Object?> get props => [];
}

/// Adds and starts validating/uploading a batch of freshly picked assets.
final class MediaUploadAssetsAdded extends MediaUploadEvent {
  const MediaUploadAssetsAdded(this.assets);

  final List<PickedAsset> assets;

  @override
  List<Object?> get props => [assets];
}

/// Adds and starts validating/uploading a single freshly picked asset.
final class MediaUploadAssetAdded extends MediaUploadEvent {
  const MediaUploadAssetAdded(this.asset);

  final PickedAsset asset;

  @override
  List<Object?> get props => [asset];
}

/// Re-attempts the upload for one failed item, reusing its stored asset.
final class MediaUploadRetryRequested extends MediaUploadEvent {
  const MediaUploadRetryRequested(this.localId);

  final String localId;

  @override
  List<Object?> get props => [localId];
}

/// Removes an item and cancels its upload if one is in flight.
final class MediaUploadRemoveRequested extends MediaUploadEvent {
  const MediaUploadRemoveRequested(this.localId);

  final String localId;

  @override
  List<Object?> get props => [localId];
}

/// Swaps the asset behind an existing item and re-uploads it, keeping the
/// same [localId] (and grid position). Best-effort deletes the previously
/// uploaded backend media it's replacing.
final class MediaUploadReplaceRequested extends MediaUploadEvent {
  const MediaUploadReplaceRequested({
    required this.localId,
    required this.newAsset,
  });

  final String localId;
  final PickedAsset newAsset;

  @override
  List<Object?> get props => [localId, newAsset];
}

/// Re-attempts every item currently in [MediaUploadStatus.failure].
final class MediaUploadRetryAllRequested extends MediaUploadEvent {
  const MediaUploadRetryAllRequested();
}

/// Seeds already-uploaded items (e.g. an edit form pre-filling from a
/// service's existing `media`) directly into state — no upload call, no
/// validation against [MediaUploadConfig] limits.
final class MediaUploadExistingItemsSeeded extends MediaUploadEvent {
  const MediaUploadExistingItemsSeeded(this.items);

  final List<MediaUploadItem> items;

  @override
  List<Object?> get props => [items];
}

/// Cancels every in-flight upload and clears all items.
final class MediaUploadClearRequested extends MediaUploadEvent {
  const MediaUploadClearRequested();
}
