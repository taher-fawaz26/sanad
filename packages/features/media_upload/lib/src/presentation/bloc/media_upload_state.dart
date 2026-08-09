part of 'media_upload_bloc.dart';

/// Aggregate upload-session state — the overall picture is always derived
/// from the individual [items], never tracked as a separate global flag.
class MediaUploadState extends Equatable {
  const MediaUploadState({
    this.items = const [],
    this.config = const MediaUploadConfig(),
  });

  final List<MediaUploadItem> items;
  final MediaUploadConfig config;

  MediaUploadItem? itemById(String localId) {
    for (final item in items) {
      if (item.localId == localId) return item;
    }
    return null;
  }

  int get uploadedCount => items.where((i) => i.isSuccess).length;

  int get uploadingCount => items.where((i) => i.isUploading).length;

  int get failedCount => items.where((i) => i.isFailure).length;

  int get pendingCount => items.where((i) => i.isPending).length;

  bool get isAtMaxFiles {
    final maxFiles = config.maxFiles;
    return maxFiles != null && items.length >= maxFiles;
  }

  MediaUploadState copyWith({List<MediaUploadItem>? items}) =>
      MediaUploadState(items: items ?? this.items, config: config);

  @override
  List<Object?> get props => [items, config];
}
