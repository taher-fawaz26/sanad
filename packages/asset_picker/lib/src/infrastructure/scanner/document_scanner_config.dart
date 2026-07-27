/// Plugin-agnostic tuning for the document-scanner presentation.
///
/// Kept free of any scanner SDK type so it can live in the public API and be
/// configured by apps without importing (or even knowing about) the concrete
/// scanner plugin.
class DocumentScannerConfig {
  const DocumentScannerConfig({
    this.frameWidthFactor = 0.85,
    this.frameHeightFactor = 0.55,
    this.requireBothSides = false,
    this.enableAutoCapture = true,
    this.showCloseButton = true,
  }) : assert(
         frameWidthFactor > 0 && frameWidthFactor <= 1,
         'frameWidthFactor must be in (0, 1]',
       ),
       assert(
         frameHeightFactor > 0 && frameHeightFactor <= 1,
         'frameHeightFactor must be in (0, 1]',
       );

  /// Capture-frame width as a fraction of the available width.
  final double frameWidthFactor;

  /// Capture-frame height as a fraction of the available height.
  final double frameHeightFactor;

  /// Require both front and back sides before finishing.
  final bool requireBothSides;

  /// Enable automatic capture with live edge detection.
  final bool enableAutoCapture;

  /// Show a close/cancel affordance in the scanner UI.
  final bool showCloseButton;
}
