import 'package:asset_picker/asset_picker.dart';
import 'package:core/core.dart';

/// Shared `AssetPicker` options for picking provider-service images.
///
/// Single source of truth for every service-image picker surface — Add
/// Service, Request New Service, and Edit Service → Manage Images — so they
/// enforce the same limits.
///
/// [remaining] bounds a multi-select batch to the free slots left under the
/// service's image cap, so a single pick can never exceed it.
AssetPickerOptions serviceImagePickerOptions({required int remaining}) =>
    AssetPickerOptions(
      allowFiles: false,
      allowMultiple: true,
      // Without this, `maxSelection` defaults to 1 and the gallery provider
      // silently truncates a multi-select down to the first asset — bound it
      // to the remaining slots instead.
      maxSelection: remaining,
      // Rejects an oversized file immediately — before it's returned to the
      // caller, so no upload, progress, or `MediaUploadBloc` item is ever
      // created for it. `MediaUploadConfig.maxFileSize` (set on each screen's
      // bloc) is a second, defensive check for anything that reaches it
      // another way (e.g. `MediaUploadReplaceRequested`).
      maxFileSize: FileSizePolicy.maxBytes,
      // SAN-576: enforce the 5 MB cap against the ORIGINAL selected file, not
      // the post-compression one. By default the picker re-encodes to JPEG at
      // acquisition, shrinking a ~7 MB pick under the cap before the size
      // check runs, so it slips through. With this flag the picker returns the
      // untouched original for validation, then still compresses it (the
      // default `compressImages`/`imageQuality`) only if it passed — so
      // compression stays enabled but can never make an oversized file
      // eligible.
      enforceSizeBeforeCompression: true,
    );
