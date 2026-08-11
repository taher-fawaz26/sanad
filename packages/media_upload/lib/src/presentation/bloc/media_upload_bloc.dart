import 'dart:async';

import 'package:asset_picker/asset_picker.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_upload/src/domain/entities/media_upload_config.dart';
import 'package:media_upload/src/domain/entities/media_upload_item.dart';
import 'package:media_upload/src/domain/entities/media_upload_status.dart';
import 'package:media_upload/src/domain/failures/media_upload_failure.dart';
import 'package:media_upload/src/domain/repositories/media_upload_repository.dart';
import 'package:media_upload/src/domain/validators/media_upload_validator.dart';

part 'media_upload_event.dart';
part 'media_upload_state.dart';

/// The single reusable upload state machine: validation → bounded-concurrency
/// upload → independent per-item progress/success/failure.
///
/// One instance is created per upload surface (a grid, a drop zone). Every
/// item's [MediaUploadStatus] evolves on its own — a failure in one item
/// never blocks or fails the others, and at most
/// `config.maxConcurrentUploads` items upload at the same time.
class MediaUploadBloc extends Bloc<MediaUploadEvent, MediaUploadState> {
  MediaUploadBloc({
    required MediaUploadRepository repository,
    MediaUploadConfig config = const MediaUploadConfig(),
  }) : _repository = repository,
       super(MediaUploadState(config: config)) {
    on<MediaUploadAssetsAdded>(_onAssetsAdded);
    on<MediaUploadAssetAdded>(_onAssetAdded);
    on<MediaUploadRetryRequested>(_onRetryRequested);
    on<MediaUploadRemoveRequested>(_onRemoveRequested);
    on<MediaUploadReplaceRequested>(_onReplaceRequested);
    on<MediaUploadRetryAllRequested>(_onRetryAllRequested);
    on<MediaUploadClearRequested>(_onClearRequested);
    on<MediaUploadExistingItemsSeeded>(_onExistingItemsSeeded);
  }

  final MediaUploadRepository _repository;

  int _activeUploads = 0;
  final List<Completer<void>> _waiters = [];

  Future<void> _onAssetsAdded(
    MediaUploadAssetsAdded event,
    Emitter<MediaUploadState> emit,
  ) => Future.wait([
    for (final asset in event.assets) _addAndUpload(asset, emit),
  ]);

  Future<void> _onAssetAdded(
    MediaUploadAssetAdded event,
    Emitter<MediaUploadState> emit,
  ) => _addAndUpload(event.asset, emit);

  Future<void> _addAndUpload(
    PickedAsset asset,
    Emitter<MediaUploadState> emit,
  ) async {
    final failure = MediaUploadValidator.validateAsset(
      asset: asset,
      config: state.config,
      currentCount: state.items.length,
    );
    final localId = generateUuidV4();
    final item = MediaUploadItem(
      localId: localId,
      asset: asset,
      status: failure != null
          ? MediaUploadStatus.failure
          : MediaUploadStatus.pending,
      failure: failure,
    );
    emit(state.copyWith(items: [...state.items, item]));

    if (failure != null) return;
    await _runUpload(localId, asset, emit);
  }

  Future<void> _onRetryRequested(
    MediaUploadRetryRequested event,
    Emitter<MediaUploadState> emit,
  ) async {
    final item = state.itemById(event.localId);
    if (item == null || !item.isFailure) return;
    await _runUpload(item.localId, item.asset, emit);
  }

  Future<void> _onRetryAllRequested(
    MediaUploadRetryAllRequested event,
    Emitter<MediaUploadState> emit,
  ) async {
    final failedItems = state.items.where((i) => i.isFailure).toList();
    await Future.wait([
      for (final item in failedItems)
        _runUpload(item.localId, item.asset, emit),
    ]);
  }

  void _onRemoveRequested(
    MediaUploadRemoveRequested event,
    Emitter<MediaUploadState> emit,
  ) {
    final item = state.itemById(event.localId);
    _repository.cancelUpload(event.localId);
    emit(
      state.copyWith(
        items: state.items.where((i) => i.localId != event.localId).toList(),
      ),
    );

    // Best-effort cleanup: the item is already gone from the grid either
    // way, so a delete failure here has nothing left to surface to the
    // user — fire-and-forget rather than blocking/reverting the removal.
    //
    // Only for items uploaded THIS session (a real local pick): an item
    // seeded via `MediaUploadItem.remote` (e.g. pre-filling an edit form
    // from a service's existing media) is already attached to that
    // service — removing it here just drops it from the next `mediaIds`
    // submission, it must NOT hard-delete the backend file before the
    // edit is even saved (the user might still discard/cancel).
    final mediaId = item?.mediaId;
    if (mediaId != null && _wasLocallyPicked(item!)) {
      unawaited(_repository.deleteMedia(mediaId).run());
    }
  }

  Future<void> _onReplaceRequested(
    MediaUploadReplaceRequested event,
    Emitter<MediaUploadState> emit,
  ) async {
    final existing = state.itemById(event.localId);
    if (existing == null) return;

    _repository.cancelUpload(event.localId);
    // Best-effort cleanup of the media this item previously pointed at —
    // see `_onRemoveRequested` for why this isn't awaited/surfaced, and why
    // remote-seeded (not-locally-picked) items are skipped.
    final previousMediaId = existing.mediaId;
    if (previousMediaId != null && _wasLocallyPicked(existing)) {
      unawaited(_repository.deleteMedia(previousMediaId).run());
    }

    final failure = MediaUploadValidator.validateAsset(
      asset: event.newAsset,
      config: state.config,
      currentCount: state.items.length - 1,
    );
    if (failure != null) {
      _setItem(
        emit,
        event.localId,
        (item) => item.copyWith(
          asset: event.newAsset,
          status: MediaUploadStatus.failure,
          failure: failure,
        ),
      );
      return;
    }

    _setItem(
      emit,
      event.localId,
      (item) => MediaUploadItem(localId: item.localId, asset: event.newAsset),
    );
    await _runUpload(event.localId, event.newAsset, emit);
  }

  void _onExistingItemsSeeded(
    MediaUploadExistingItemsSeeded event,
    Emitter<MediaUploadState> emit,
  ) {
    emit(state.copyWith(items: [...state.items, ...event.items]));
  }

  void _onClearRequested(
    MediaUploadClearRequested event,
    Emitter<MediaUploadState> emit,
  ) {
    for (final item in state.items) {
      _repository.cancelUpload(item.localId);
    }
    emit(state.copyWith(items: const []));
  }

  Future<void> _runUpload(
    String localId,
    PickedAsset asset,
    Emitter<MediaUploadState> emit,
  ) async {
    await _acquireSlot();
    if (emit.isDone) {
      _releaseSlot();
      return;
    }

    _setItem(
      emit,
      localId,
      (item) => item.copyWith(
        status: MediaUploadStatus.uploading,
        progress: 0,
        failure: null,
      ),
    );

    final result = await _repository
        .upload(
          uploadKey: localId,
          asset: asset,
          onProgress: (progress) {
            if (emit.isDone) return;
            _setItem(
              emit,
              localId,
              (item) => item.copyWith(progress: progress),
            );
          },
        )
        .run();

    _releaseSlot();
    if (emit.isDone) return;

    result.fold(
      (failure) => _setItem(
        emit,
        localId,
        (item) => item.copyWith(
          status: MediaUploadStatus.failure,
          failure: UploadRequestFailure(failure.message),
        ),
      ),
      (media) => _setItem(
        emit,
        localId,
        (item) => item.copyWith(
          status: MediaUploadStatus.success,
          mediaId: media.mediaId,
          url: media.url,
          originalName: media.originalName,
          fileName: media.fileName,
          mimeType: media.mimeType,
          size: media.size,
          progress: 1,
          failure: null,
        ),
      ),
    );
  }

  /// Waits for a free concurrency slot (bounded by
  /// `config.maxConcurrentUploads`). Handoff on release goes straight to the
  /// next waiter without touching [_activeUploads], so there is no race
  /// between a freshly-released slot and a new fast-path acquire.
  Future<void> _acquireSlot() {
    if (_activeUploads < state.config.maxConcurrentUploads) {
      _activeUploads++;
      return Future.value();
    }
    final completer = Completer<void>();
    _waiters.add(completer);
    return completer.future;
  }

  void _releaseSlot() {
    if (_waiters.isNotEmpty) {
      _waiters.removeAt(0).complete();
    } else {
      _activeUploads--;
    }
  }

  /// `true` for an item backed by a real local file/bytes pick this session
  /// — `false` for one seeded via `MediaUploadItem.remote` (whose
  /// placeholder asset has an empty [PickedAsset.path] and no
  /// [PickedAsset.bytes]).
  bool _wasLocallyPicked(MediaUploadItem item) =>
      item.asset.path.isNotEmpty || (item.asset.bytes?.isNotEmpty ?? false);

  void _setItem(
    Emitter<MediaUploadState> emit,
    String localId,
    MediaUploadItem Function(MediaUploadItem item) update,
  ) {
    final items = [
      for (final item in state.items)
        if (item.localId == localId) update(item) else item,
    ];
    emit(state.copyWith(items: items));
  }
}
