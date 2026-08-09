# media_upload

Feature-agnostic pick → validate → upload → per-item progress/retry pipeline.
Sits on top of `asset_picker`'s picking primitives and beneath `shared_ui`'s
`MediaUploadGrid`/`MediaUploadTile`/`MediaUploadDropZone` widgets.

```
asset_picker  →  media_upload  →  shared_ui widgets  →  feature business logic
```

This package knows nothing about registration, organization settings,
products, branches, or any other business entity. It only produces an
`UploadedMedia` with a `mediaId`; the owning feature performs its own
attach/replace API call with that id.

## Usage

```dart
class ProfileImagePicker extends StatelessWidget {
  const ProfileImagePicker({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MediaUploadBloc>(
        param1: const MediaUploadConfig(
          maxFiles: 8,
          maxFileSize: 5 * 1024 * 1024,
          allowedMimeTypes: [
            'image/jpeg',
            'image/png',
            'image/webp',
          ],
        ),
      ),
      child: BlocBuilder<MediaUploadBloc, MediaUploadState>(
        builder: (context, state) {
          return MediaUploadGrid(
            items: [
              for (final item in state.items)
                MediaUploadTileData(
                  id: item.localId,
                  previewUrl: item.url,
                  fileName: item.fileName,
                  progress: item.progress,
                  status: switch (item.status) {
                    MediaUploadStatus.pending => MediaUploadTileStatus.pending,
                    MediaUploadStatus.uploading => MediaUploadTileStatus.uploading,
                    MediaUploadStatus.success => MediaUploadTileStatus.success,
                    MediaUploadStatus.failure => MediaUploadTileStatus.failure,
                  },
                  errorMessage: item.failure?.message,
                ),
            ],
            maxFiles: state.config.maxFiles,
            onAdd: () async {
              final result = await AssetPicker.pick(context);
              if (!result.hasAssets) return;
              context
                  .read<MediaUploadBloc>()
                  .add(MediaUploadAssetsAdded(result.assets));
            },
            onRetry: (id) =>
                context.read<MediaUploadBloc>().add(MediaUploadRetryRequested(id)),
            onRemove: (id) =>
                context.read<MediaUploadBloc>().add(MediaUploadRemoveRequested(id)),
            onRetryAll: () =>
                context.read<MediaUploadBloc>().add(const MediaUploadRetryAllRequested()),
          );
        },
      ),
    );
  }
}
```

Once an item reaches `MediaUploadStatus.success`, read `item.mediaId` and
perform your feature's own attach call, e.g.:

```dart
final mediaId = state.items.first.mediaId!;
await profileRepository.setProfileImage(mediaId: mediaId); // PATCH /service-provider/profile-image
```

## What this package does NOT do

- It does not attach media to any business entity — that is always the
  calling feature's job, via its own endpoint.
- It does not delete previously uploaded media — no delete endpoint exists.
  `MediaUploadReplaceRequested` uploads a new file and returns a new
  `UploadedMedia`; the feature decides how to swap it in.
- It does not know about `registration` or `organization_settings` — both
  currently keep their own separate upload implementations; migrating them
  onto this package is a deliberate follow-up, not done here.
