# document_validation

Client-side, pre-upload document-type gate for `document_flow` — answers only
*"is this the requested document type?"*, never expiry/authenticity/ownership
(the backend remains authoritative after upload).

- **Emirates ID**: `google_mlkit_text_recognition` reads the scanner-captured
  image, and `EmiratesIdSignalPolicy` scores the recognized text against
  known Emirates ID signals (federal-authority wording, the ID-number
  pattern — never a single generic word).
- **Trade License**: `flutter_tesseract_ocr` reads the image, and
  `TradeLicenseSignalPolicy` scores the OCR text against known Trade License
  signals (never a single generic word — see the policy's doc comment).

This is the **only** package in the workspace that imports
`google_mlkit_text_recognition` and `flutter_tesseract_ocr`. Everything else
depends on `document_flow`'s `DocumentTypeValidator` abstraction; this
package supplies the implementation via `DocumentValidationDI.init()`.

## Why not `eid_scanner`?

The feature spec named `eid_scanner` for Emirates ID. It was rejected after
dependency verification: it pins `camera: 0.10.4` (exact) and
`google_ml_kit: ^0.19.0` (→ `google_mlkit_text_recognition: ^0.14.0`), both
of which conflict with `document_camera_frame` — the in-app document scanner
`asset_picker` already uses in production (`camera: ^0.12.0+1`,
`google_mlkit_text_recognition: 0.15.1`, both already resolved in this
workspace's lockfile). `flutter pub get` fails outright on the first
conflict; forcing `camera` via `dependency_overrides` only surfaces the
second, independent ML-Kit conflict underneath it — `eid_scanner` (last
published ~17 months before this decision) is fundamentally incompatible
with the scanner stack already shipping here.

Instead, `EmiratesIdScannerDataSource` uses
`google_mlkit_text_recognition` directly, pinned to the exact version
(`0.15.1`) `document_camera_frame` already requires — no new conflicts —
and `EmiratesIdSignalPolicy` (mirroring `TradeLicenseSignalPolicy`'s
approach) classifies the recognized text. Capture still goes through the
existing in-app scanner (`AssetSource.scanner` in `asset_picker`); only the
post-capture classification engine changed from the spec's literal package
name.

## Bundled tessdata

`assets/tessdata/` ships exactly two trained-data files, both from the
official [`tessdata_fast`](https://github.com/tesseract-ocr/tessdata_fast)
release (the size/speed-optimized variant — appropriate for a mobile,
pre-upload gate rather than a document-archival OCR pipeline):

| File | Language | Why bundled |
|---|---|---|
| `eng.traineddata` | English | English-language UAE Trade Licenses. |
| `ara.traineddata` | Arabic | Arabic-language UAE Trade Licenses — UAE Trade Licenses are commonly bilingual, so Arabic support is not optional. |

`FlutterTesseractOcr.extractText` is called with `language: 'ara+eng'` so a
single OCR pass reads bilingual documents (English section *and* Arabic
section) without a language-detection pre-step. `assets/tessdata_config.json`
lists the same two files for the plugin's Android asset-copy step.

No other language is bundled — Emirates ID validation uses
`google_mlkit_text_recognition` (Latin script only; see "Why not
`eid_scanner`?" below), not Tesseract, so only the Trade License surface
needs trained data.

## iOS build step (manual, one-time)

`flutter_tesseract_ocr` reads trained-data files from a native filesystem
path it manages itself, not directly from the Flutter asset bundle — on iOS
this requires the `assets/tessdata/` folder to also be added as a folder
reference under `Runner` in Xcode (`Runner.xcodeproj` → right-click `Runner`
→ *Add Files to "Runner"...* → select this package's `assets/tessdata`
folder → **Create folder references** (blue folder icon, not yellow group)
→ ensure "Copy items if needed" is unchecked and the `Runner` target is
checked). This is a native project-file change outside Dart source control
for `sanad_provider/ios/Runner.xcodeproj` and must be done once by whoever
next opens the iOS project in Xcode; Android needs no equivalent step
(`assets/tessdata_config.json` covers it via the plugin's Gradle task).
