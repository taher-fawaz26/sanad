# asset_picker

> The single source of truth for **working with external assets** in the Sanad
> monorepo — acquire (camera, gallery, files, document scans), **preview**,
> **thumbnail**, and carry generic **upload state** — behind a plugin-agnostic,
> dependency-inverted API.

This package is a generic **asset platform**. It knows nothing about KYC,
signup, profile, chat, branches, workers, services, or any other feature. Any
feature that needs to pick, show, or track an asset depends on this package and
nothing lower-level.

Beyond acquisition it provides three reusable building blocks:

- **Preview** — `AssetPreview.show(...)` / `AssetPreviewPage` (images zoom;
  PDFs and other files show a document card).
- **Thumbnails** — `AssetThumbnail`, a type-aware widget that eliminates
  duplicated "which icon/preview for this file?" logic.
- **Upload lifecycle model** — `UploadStatus` + `UploadableAsset`, a pure
  foundation future upload managers consume (no networking is implemented
  here).

---

## Table of Contents

1. [Design goals](#design-goals)
2. [Architecture](#architecture)
3. [Setup (DI)](#setup-di)
4. [Public API](#public-api)
5. [Examples](#examples)
6. [Options reference](#options-reference)
7. [Validation](#validation)
8. [Preview](#preview)
9. [Thumbnails](#thumbnails)
10. [Upload lifecycle model](#upload-lifecycle-model)
11. [Document scanner](#document-scanner)
12. [Theming](#theming)
13. [Extending providers](#extending-providers)
14. [Testing](#testing)
15. [Roadmap / future-ready](#roadmap--future-ready)

---

## Design goals

- **Never expose third-party plugins.** Features must not know whether the
  package uses `image_picker`, `file_picker`, or a scanning SDK. Everything is
  hidden behind interfaces; the concrete plugin wrappers are *not exported*.
- **Dependency inverted.** The app-facing type is the `AssetPickerService`
  abstraction, registered through DI. The `AssetPicker` facade resolves it from
  the service locator, so apps can replace it, mock it in tests, or provide a
  platform-specific implementation without changing any feature code.
- **No static global state, no business logic.** The facade is a thin,
  state-free delegate; all behaviour lives in the injected service.
- **Configurable & future-ready.** New sources (cloud drives, clipboard),
  new capabilities (OCR, PDF merge, cropping) can be added without breaking the
  public API.

---

## Architecture

Clean architecture, matching the rest of the monorepo:

```
lib/
  asset_picker.dart                 ← barrel (public surface only)
  src/
    asset_picker_facade.dart        ← AssetPicker (DI-resolving facade)

    domain/                         ← pure Dart, no Flutter, no plugins
      entities/
        picked_asset.dart           ← PickedAsset (the ONLY asset shape apps see)
        asset_picker_result.dart    ← AssetPickerResult (assets, source, cancelled)
        asset_picker_options.dart   ← AssetPickerOptions (fully declarative config)
      enums/
        asset_source.dart           ← camera | gallery | files | scanner
        asset_type.dart             ← image | video | audio | pdf | document | any
      failures/
        asset_picker_exception.dart ← sealed exception hierarchy
      validation/
        asset_validation_error.dart ← descriptive, typed errors
        asset_validator.dart        ← AssetValidator + DefaultAssetValidator
      services/
        asset_picker_service.dart   ← the DI-registered abstraction
      upload/                       ← generic upload lifecycle model (no I/O)
        upload_status.dart          ← UploadStatus enum
        uploadable_asset.dart       ← UploadableAsset wrapper + transitions

    infrastructure/
      providers/                    ← ABSTRACT contracts (exported)
        camera_provider.dart
        gallery_provider.dart
        file_provider.dart
        scanner_provider.dart
      implementations/              ← plugin wrappers (NOT exported)
        image_picker_provider.dart              → camera + gallery
        file_picker_provider.dart               → files
        document_camera_provider.dart           → scanner fallback (camera JPEG)
        document_camera_frame_scanner_provider  → real scanner (SDK-isolated)
      scanner/
        document_scanner_config.dart  ← plugin-agnostic scanner tuning (exported)
      services/
        asset_picker_service_impl.dart  ← orchestrator (route → acquire → validate)

    presentation/
      sheets/asset_source_sheet.dart    ← auto-generated source picker sheet
      widgets/asset_picker_tile.dart    ← a single source row
      widgets/asset_thumbnail.dart      ← type-aware thumbnail
      preview/                          ← generic, reusable preview
        asset_preview.dart              ← AssetPreview facade (show / openPage)
        asset_preview_content.dart      ← shared type-aware body
        asset_preview_dialog.dart       ← compact single-asset dialog
        asset_preview_page.dart         ← full-screen (swipeable) gallery

    theme/asset_picker_theme.dart       ← AssetPickerTheme (design-system driven)

    di/
      asset_picker_config.dart          ← composition-root config
      asset_picker_di.dart              ← sl registration
      asset_picker_module.dart          ← FeatureModule wrapper

    utils/asset_mime_resolver.dart      ← internal MIME lookup
```

**Dependency rule:** the `domain/` layer imports no Flutter and no plugins
(enforced by `scan_imports.dart`). Plugins are referenced *only* inside
`infrastructure/implementations/`, and those files are never exported from the
barrel — so no plugin type can leak into feature code.

---

## Setup (DI)

The package integrates with the shared `FeatureModule` / `ModuleRegistry`
system. Register it once during app bootstrap:

```dart
import 'package:asset_picker/asset_picker.dart';

ModuleRegistry([
  // ...other modules
  AssetPickerModule(),                       // batteries-included defaults
]);
```

Or imperatively:

```dart
AssetPickerDI.init();
```

Both wire up the default providers (`image_picker` for camera/gallery,
`file_picker` for files, and — depending on config — either the real
`document_camera_frame` scanner or the camera-based JPEG fallback; see
[Document scanner](#document-scanner)) and register the `AssetPickerService` +
`AssetPickerConfig` on the shared `sl` locator.

---

## Public API

The facade is the entry point. It resolves `AssetPickerService` via DI.

```dart
// Shows the design-system source sheet (only for >1 enabled source):
Future<AssetPickerResult> AssetPicker.pick(BuildContext context, {AssetPickerOptions? options});

// Shortcuts — NO bottom sheet, go straight to the source:
Future<AssetPickerResult> AssetPicker.pickCamera({AssetPickerOptions? options});
Future<AssetPickerResult> AssetPicker.pickGallery({AssetPickerOptions? options});
Future<AssetPickerResult> AssetPicker.pickFile({AssetPickerOptions? options});
Future<AssetPickerResult> AssetPicker.scanDocument({AssetPickerOptions? options});
```

Every call returns an `AssetPickerResult` (never `null`):

```dart
class AssetPickerResult {
  final List<PickedAsset> assets;
  final AssetSource? source;
  final bool cancelled;

  bool get hasAssets;
  bool get isEmpty;
  PickedAsset? get single;
}
```

User cancellation is a normal result (`cancelled == true`). Hard failures throw
a sealed `AssetPickerException`:
`AssetPermissionDeniedException`, `AssetSourceUnavailableException`,
`AssetValidationException`, `AssetPickerPlatformException`.

---

## Examples

### Pick anything with the source sheet

```dart
final result = await AssetPicker.pick(context);
if (result.hasAssets) {
  final PickedAsset asset = result.single!;
  // asset.name, asset.path, asset.bytes, asset.mimeType, asset.size, asset.assetType
}
```

### A single profile photo (camera or gallery only)

```dart
final result = await AssetPicker.pick(
  context,
  options: const AssetPickerOptions(
    allowFiles: false,
    allowScanner: false,
    allowedAssetTypes: [AssetType.image],
    maxFileSize: 5 * 1024 * 1024, // 5 MB
    sheetTitle: 'Update photo',
  ),
);
```

### Attach up to 5 PDFs / documents

```dart
final result = await AssetPicker.pickFile(
  options: const AssetPickerOptions(
    allowMultiple: true,
    maxSelection: 5,
    allowedAssetTypes: [AssetType.pdf, AssetType.document],
    loadBytes: true, // if you need the bytes for upload
  ),
);
```

### Scan a document (no sheet)

```dart
final result = await AssetPicker.scanDocument();
final scan = result.single; // a JPEG PickedAsset
```

### Handle failures

```dart
try {
  final result = await AssetPicker.pick(context);
  // ...
} on AssetValidationException catch (e) {
  for (final error in e.errors) {
    showSnack(error.message); // descriptive, ready to display
  }
} on AssetPermissionDeniedException catch (e) {
  if (e.permanentlyDenied) openAppSettings();
} on AssetPickerException catch (e) {
  showSnack(e.message);
}
```

---

## Options reference

`AssetPickerOptions` is fully declarative; every field has a sensible default.

| Field | Default | Purpose |
|-------|---------|---------|
| `allowCamera` / `allowGallery` / `allowFiles` | `true` | Offer these sources |
| `allowScanner` | `false` | Offer the document scanner |
| `allowMultiple` | `false` | Allow multi-selection |
| `maxSelection` | `1` | Max items (when multiple) |
| `maxFileSize` | `null` | Max bytes per asset |
| `allowedExtensions` | `null` | Extension allow-list |
| `allowedMimeTypes` | `null` | MIME allow-list |
| `allowedAssetTypes` | `null` | Logical-type allow-list |
| `title` / `subtitle` / `sheetTitle` | `null` | Copy overrides |
| `confirmText` / `cancelText` | `null` | Button copy overrides |
| `showSearch` / `showPreview` | `false` / `true` | UI toggles |
| `compressImages` / `enableCompression` | `true` | Image compression (via `imageQuality`) |
| `imageQuality` | `85` | JPEG/WebP quality 0–100 |
| `cropImages` / `enableCropping` | `false` | Cropping *(future-ready)* |
| `enablePdfGeneration` | `false` | PDF from scans *(future-ready)* |
| `loadBytes` | `false` | Eagerly load `PickedAsset.bytes` |

Fields marked *future-ready* are accepted today and become active when a
capable provider is registered — no API change required.

---

## Validation

`AssetPickerServiceImpl` runs every selection through an `AssetValidator`. The
`DefaultAssetValidator` enforces count, size, extension, MIME, and asset-type
constraints and produces **descriptive**, typed `AssetValidationError`s. On any
violation the service throws `AssetValidationException(errors)`.

Supply a custom validator (e.g. to add business rules) via
`AssetPickerConfig.validator` — the pipeline is unchanged.

---

## Preview

Generic, business-agnostic preview components pick how to render an asset
automatically from its `AssetType`: **images** are zoomable/pannable; **PDFs**
and other files show a document card (thumbnail + name + size + optional
"Open"). No PDF renderer is bundled — inject one per type via `previewBuilder`
if you want in-app PDF rendering.

```dart
// Quick single-asset dialog:
await AssetPreview.show(context, asset: myAsset);

// Full-screen, swipeable gallery (multiple assets ⇒ page automatically):
await AssetPreview.show(context, assets: myAssets, asPage: true);

// Or push the page directly:
Navigator.of(context).push(
  MaterialPageRoute(builder: (_) => AssetPreviewPage(assets: myAssets)),
);

// Let the host decide how to open non-inline files (package stays generic):
await AssetPreview.show(
  context,
  asset: pdf,
  onOpen: (a) => myOpenExternally(a.path),
  previewBuilder: (ctx, a) => MyPdfViewer(path: a.path), // optional real renderer
);
```

---

## Thumbnails

`AssetThumbnail` renders the right visual for any asset, removing duplicated
icon/preview logic from features:

| Asset | Rendered as |
|-------|-------------|
| Image | the actual image (bytes or file), cropped to fit |
| PDF | PDF glyph on a tinted surface |
| Word / Excel / … | document glyph |
| Unknown / other | generic file glyph |

```dart
AssetThumbnail(
  asset: asset,
  size: 56,
  borderRadius: AppRadius.circularMd, // optional
  backgroundColor: null,              // defaults to DS tint
  fit: BoxFit.cover,
  placeholder: null,                  // optional custom fallback
);
```

All defaults come from the design system; every visual aspect is overridable.

---

## Upload lifecycle model

A **pure, generic** foundation for future upload managers (chat attachments,
KYC, profile images, branch/worker documents). **No uploading, no networking,
no API calls are implemented here** — only the state model.

```dart
enum UploadStatus { pending, uploading, uploaded, failed, retry }

class UploadableAsset {           // wraps a PickedAsset with upload state
  final PickedAsset asset;
  final UploadStatus status;      // default: pending
  final double progress;          // 0.0 – 1.0
  final String? error;
  final String? remoteId;         // assigned by a backend once uploaded
  final String? remoteUrl;
}
```

Immutable pure state-transition helpers let a manager evolve assets without
this package knowing how they are transported:

```dart
final queue = pickedAssets.toUploadable();          // all pending
var item = queue.first
  .markUploading(0.4)
  .markUploaded(remoteId: 'abc', remoteUrl: 'https://cdn/abc.jpg');
// on error: item.markFailed('no network').markRetry();
```

---

## Document scanner

The scanner is fully isolated behind `ScannerProvider`; the rest of the package
never knows which SDK backs it.

- **Real scanner** — `document_camera_frame` provides auto **edge detection**,
  **perspective correction**, **cropping**, and **JPEG output**. Enable it by
  supplying your app's root navigator key (the scanner is a Flutter page, so it
  needs a navigator — the `ScannerProvider.scan` contract stays context-free):

  ```dart
  AssetPickerModule(
    config: AssetPickerConfig(
      scannerNavigatorKey: myRootNavigatorKey,          // GlobalKey<NavigatorState>
      documentScannerConfig: const DocumentScannerConfig(
        requireBothSides: false,
        enableAutoCapture: true,
      ),
    ),
  );
  ```

- **Zero-config fallback** — without a navigator key (or a custom provider) the
  package uses a camera-based JPEG scanner so it still works out of the box.

Either way, features call `AssetPicker.scanDocument()` / `AssetPicker.pick(...)`
identically. To use a different SDK entirely, implement `ScannerProvider` and
pass it as `AssetPickerConfig.scannerProvider`.

---

## Theming

`AssetPickerTheme.of(context)` builds a theme straight from the design system
(`context.appColors`, `context.appTypography`, `AppSpacing`, `AppRadius`). The
source sheet generates itself from the enabled options and paints with this
theme. Override any slice without forking widgets:

```dart
AssetPickerModule(
  config: AssetPickerConfig(
    texts: const AssetPickerTexts(sheetTitle: 'Add a file'),
    icons: const AssetPickerIcons(camera: Icons.camera_alt),
    // or fully: themeBuilder: (context) => AssetPickerTheme.of(context, ...),
  ),
);
```

---

## Extending providers

Every source is an interface. To swap an implementation — say, a real document
scanner SDK — implement the interface and register it. **No feature code
changes.**

```dart
class DocScannerFrameProvider implements ScannerProvider {
  @override
  Future<List<PickedAsset>> scan(AssetPickerOptions options) async {
    final pages = await MyScannerSdk.scan(); // edge detection, perspective, crop
    return pages.map((p) => PickedAsset(
      name: p.fileName,
      path: p.path,
      mimeType: 'image/jpeg',
      size: p.sizeBytes,
      assetType: AssetType.image,
    )).toList();
  }
}

// Register it:
AssetPickerModule(
  config: AssetPickerConfig(scannerProvider: DocScannerFrameProvider()),
);
```

Adding a **new source** (e.g. Google Drive) is additive:

1. Add a value to `AssetSource`.
2. Define a `CloudProvider` interface + implementation.
3. Wire it in `AssetPickerServiceImpl` / `AssetPickerConfig`.

Existing call sites keep compiling.

---

## Testing

Because the app depends on the `AssetPickerService` abstraction, mocking is
trivial:

```dart
class MockAssetPickerService extends Mock implements AssetPickerService {}

sl.registerSingleton<AssetPickerService>(MockAssetPickerService());
when(() => service.pickCamera(options: any(named: 'options')))
    .thenAnswer((_) async => AssetPickerResult.success(
          assets: [fakeAsset],
          source: AssetSource.camera,
        ));
```

The package ships unit tests for the validator, options, result, enums, MIME
resolver, and the service orchestrator (with mocked providers). Run them with:

```bash
flutter test
```

---

## Roadmap / future-ready

The API is designed so these are **additive**, not breaking:

- Cloud providers (Google Drive, Dropbox, OneDrive, iCloud)
- Clipboard image, recent files, recent scans
- OCR, barcode/QR scanning, document classification
- Face capture, signature capture
- PDF generation / merge / split, multi-page scans
- Image compression tuning, image editing
- Video & voice recording
