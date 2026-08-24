import 'package:asset_picker/src/domain/enums/asset_type.dart';
import 'package:asset_picker/src/infrastructure/scanner/document_scanner_config.dart';
import 'package:equatable/equatable.dart';

/// Fully declarative configuration for a single pick operation.
///
/// Every field has a sensible default, so `const AssetPickerOptions()` is a
/// valid single-image, single-selection configuration. Callers override only
/// what they care about.
///
/// Options are split into three concerns:
/// * **Sources** — which acquisition sources are offered (`allow*`).
/// * **Selection & validation** — how many / how large / which types.
/// * **Copy** — user-facing text overrides (fall back to `AssetPickerTheme`).
///
/// Capability flags whose pipelines are not yet implemented
/// ([enableCropping], [enablePdfGeneration]) are accepted today and documented
/// as *future-ready*: wiring a provider for them later requires no API change.
class AssetPickerOptions extends Equatable {
  const AssetPickerOptions({
    this.allowCamera = true,
    this.allowGallery = true,
    this.allowFiles = true,
    this.allowScanner = false,
    this.allowMultiple = false,
    this.maxSelection = 1,
    this.maxFileSize,
    this.allowedExtensions,
    this.allowedMimeTypes,
    this.allowedAssetTypes,
    this.title,
    this.subtitle,
    this.sheetTitle,
    this.confirmText,
    this.cancelText,
    this.showSearch = false,
    this.showPreview = true,
    this.compressImages = true,
    this.cropImages = false,
    this.enableCompression = true,
    this.enableCropping = false,
    this.enablePdfGeneration = false,
    this.imageQuality = 85,
    this.loadBytes = false,
    this.requireBothSides = false,
    this.scannerConfig,
  }) : assert(maxSelection >= 1, 'maxSelection must be at least 1'),
       assert(
         imageQuality >= 0 && imageQuality <= 100,
         'imageQuality must be between 0 and 100',
       );

  // ── Sources ────────────────────────────────────────────────────────────────

  /// Offer the device camera as a source.
  final bool allowCamera;

  /// Offer the photo gallery as a source.
  final bool allowGallery;

  /// Offer the file browser as a source.
  final bool allowFiles;

  /// Offer the document scanner as a source. Disabled by default.
  final bool allowScanner;

  // ── Selection & validation ───────────────────────────────────────────────

  /// Allow selecting more than one asset in a single operation.
  final bool allowMultiple;

  /// Hard cap on the number of assets a single operation may return.
  /// Ignored when [allowMultiple] is `false` (treated as 1).
  final int maxSelection;

  /// Maximum size, in bytes, of any single asset. `null` defers to the
  /// app-wide `FileSizePolicy` maximum — `DefaultAssetValidator` clamps
  /// whatever is set here against that global ceiling, so this can tighten
  /// it but never loosen it beyond the global maximum.
  final int? maxFileSize;

  /// Explicit allow-list of bare extensions (no leading dot, case-insensitive).
  /// `null` derives the allow-list from [allowedAssetTypes] when present.
  final List<String>? allowedExtensions;

  /// Explicit allow-list of MIME types. `null` means unconstrained.
  final List<String>? allowedMimeTypes;

  /// Allow-list of logical [AssetType]s. `null` (or containing [AssetType.any])
  /// means unconstrained.
  final List<AssetType>? allowedAssetTypes;

  // ── Copy (user-facing text) ──────────────────────────────────────────────

  /// Optional header title rendered above the picker UI.
  final String? title;

  /// Optional supporting subtitle.
  final String? subtitle;

  /// Optional title for the source-selection bottom sheet.
  final String? sheetTitle;

  /// Optional confirm-button label (multi-select flows).
  final String? confirmText;

  /// Optional cancel-button label.
  final String? cancelText;

  // ── Behaviour flags ──────────────────────────────────────────────────────

  /// Show an in-picker search field where the underlying source supports it.
  final bool showSearch;

  /// Show a preview of the selection before confirming (future-ready).
  final bool showPreview;

  /// Compress captured / picked images (honoured via [imageQuality]).
  final bool compressImages;

  /// Crop images after capture (future-ready — requires a cropping provider).
  final bool cropImages;

  /// Master switch enabling the compression pipeline stage.
  final bool enableCompression;

  /// Master switch enabling the cropping pipeline stage (future-ready).
  final bool enableCropping;

  /// Master switch enabling PDF generation from scans/images (future-ready).
  final bool enablePdfGeneration;

  /// JPEG/WebP quality applied when [compressImages] and [enableCompression]
  /// are both set. Range `0`–`100`.
  final int imageQuality;

  /// Eagerly load each asset's bytes into memory (`PickedAsset.bytes`).
  /// Off by default to avoid holding large files in memory unnecessarily.
  final bool loadBytes;

  /// Request both document sides (front and back) in a single scan session.
  ///
  /// Only honoured by scanner providers that support multi-side capture
  /// (e.g. [DocumentCameraFrameScannerProvider]). When `true`, the scanner
  /// returns two [PickedAsset]s — front first, back second.
  final bool requireBothSides;

  /// Per-call override for the scanner presentation (title, side labels,
  /// instructions). When non-null, the scanner provider uses this instead of
  /// its app-wide singleton config — so each capture action can show
  /// document-type-specific copy without changing the global registration.
  final DocumentScannerConfig? scannerConfig;

  /// The effective maximum number of assets, collapsing [allowMultiple] and
  /// [maxSelection] into a single value.
  int get effectiveMaxSelection => allowMultiple ? maxSelection : 1;

  /// Whether image compression should actually be applied.
  bool get shouldCompress => enableCompression && compressImages;

  /// The set of allowed extensions this configuration resolves to, or `null`
  /// when the selection is unconstrained by extension. Combines
  /// [allowedExtensions] with the default extensions of [allowedAssetTypes].
  Set<String>? get resolvedAllowedExtensions {
    final explicit = allowedExtensions
        ?.map((e) => e.replaceFirst('.', '').toLowerCase())
        .toSet();
    final fromTypes = allowedAssetTypes
        ?.where((t) => t != AssetType.any)
        .expand((t) => t.defaultExtensions)
        .toSet();

    if ((explicit == null || explicit.isEmpty) &&
        (fromTypes == null || fromTypes.isEmpty)) {
      return null;
    }
    return {...?explicit, ...?fromTypes};
  }

  /// Whether at least one source is enabled.
  bool get hasAnySource =>
      allowCamera || allowGallery || allowFiles || allowScanner;

  /// Whether exactly one source is enabled — the sheet is skipped in this case.
  bool get hasSingleSource {
    final count = [
      allowCamera,
      allowGallery,
      allowFiles,
      allowScanner,
    ].where((e) => e).length;
    return count == 1;
  }

  /// Returns a copy with selected fields overridden.
  AssetPickerOptions copyWith({
    bool? allowCamera,
    bool? allowGallery,
    bool? allowFiles,
    bool? allowScanner,
    bool? allowMultiple,
    int? maxSelection,
    int? maxFileSize,
    List<String>? allowedExtensions,
    List<String>? allowedMimeTypes,
    List<AssetType>? allowedAssetTypes,
    String? title,
    String? subtitle,
    String? sheetTitle,
    String? confirmText,
    String? cancelText,
    bool? showSearch,
    bool? showPreview,
    bool? compressImages,
    bool? cropImages,
    bool? enableCompression,
    bool? enableCropping,
    bool? enablePdfGeneration,
    int? imageQuality,
    bool? loadBytes,
    bool? requireBothSides,
    DocumentScannerConfig? scannerConfig,
  }) {
    return AssetPickerOptions(
      allowCamera: allowCamera ?? this.allowCamera,
      allowGallery: allowGallery ?? this.allowGallery,
      allowFiles: allowFiles ?? this.allowFiles,
      allowScanner: allowScanner ?? this.allowScanner,
      allowMultiple: allowMultiple ?? this.allowMultiple,
      maxSelection: maxSelection ?? this.maxSelection,
      maxFileSize: maxFileSize ?? this.maxFileSize,
      allowedExtensions: allowedExtensions ?? this.allowedExtensions,
      allowedMimeTypes: allowedMimeTypes ?? this.allowedMimeTypes,
      allowedAssetTypes: allowedAssetTypes ?? this.allowedAssetTypes,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      sheetTitle: sheetTitle ?? this.sheetTitle,
      confirmText: confirmText ?? this.confirmText,
      cancelText: cancelText ?? this.cancelText,
      showSearch: showSearch ?? this.showSearch,
      showPreview: showPreview ?? this.showPreview,
      compressImages: compressImages ?? this.compressImages,
      cropImages: cropImages ?? this.cropImages,
      enableCompression: enableCompression ?? this.enableCompression,
      enableCropping: enableCropping ?? this.enableCropping,
      enablePdfGeneration: enablePdfGeneration ?? this.enablePdfGeneration,
      imageQuality: imageQuality ?? this.imageQuality,
      loadBytes: loadBytes ?? this.loadBytes,
      requireBothSides: requireBothSides ?? this.requireBothSides,
      scannerConfig: scannerConfig ?? this.scannerConfig,
    );
  }

  @override
  List<Object?> get props => [
    allowCamera,
    allowGallery,
    allowFiles,
    allowScanner,
    allowMultiple,
    maxSelection,
    maxFileSize,
    allowedExtensions,
    allowedMimeTypes,
    allowedAssetTypes,
    title,
    subtitle,
    sheetTitle,
    confirmText,
    cancelText,
    showSearch,
    showPreview,
    compressImages,
    cropImages,
    enableCompression,
    enableCropping,
    enablePdfGeneration,
    imageQuality,
    loadBytes,
    requireBothSides,
    scannerConfig,
  ];
}
