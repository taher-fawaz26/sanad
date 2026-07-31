import 'package:flutter/material.dart';

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
    this.primaryColor,
    this.showInstructionText = false,
    this.frontSideInstruction,
    this.backSideInstruction,
    this.captureFrontButtonText,
    this.captureBackButtonText,
    this.retakeButtonText,
    this.saveButtonText,
    this.nextButtonText,
    this.previousButtonText,
    this.frontSideTitle,
    this.backSideTitle,
    this.screenTitle,
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

  /// Brand accent color applied to active states, animations, and the progress
  /// bar inside the scanner UI. Null uses the package's built-in defaults.
  final Color? primaryColor;

  // ── Instruction texts ────────────────────────────────────────────────────

  /// Whether the static instruction text strip is visible.
  final bool showInstructionText;

  /// Instruction shown during front-side capture (e.g. "Place the front of
  /// your Emirates ID in the frame").
  final String? frontSideInstruction;

  /// Instruction shown during back-side capture.
  final String? backSideInstruction;

  // ── Button texts ─────────────────────────────────────────────────────────

  /// Label on the capture button when scanning the front side.
  final String? captureFrontButtonText;

  /// Label on the capture button when scanning the back side.
  final String? captureBackButtonText;

  /// Label on the retake button.
  final String? retakeButtonText;

  /// Label on the save / confirm button.
  final String? saveButtonText;

  /// Label on the "next" button (front → back transition).
  final String? nextButtonText;

  /// Label on the "previous" button (back → front, shown after front captured).
  final String? previousButtonText;

  // ── Title texts ───────────────────────────────────────────────────────────

  /// Overall screen title shown at the top of the scanner UI.
  final String? screenTitle;

  /// Title shown in the scanner header during front-side capture.
  final String? frontSideTitle;

  /// Title shown in the scanner header during back-side capture.
  final String? backSideTitle;
}
