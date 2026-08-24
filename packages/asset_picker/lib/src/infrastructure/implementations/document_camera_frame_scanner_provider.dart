import 'dart:io';

import 'package:asset_picker/src/domain/entities/asset_picker_options.dart';
import 'package:asset_picker/src/domain/entities/picked_asset.dart';
import 'package:asset_picker/src/domain/enums/asset_source.dart';
import 'package:asset_picker/src/domain/enums/asset_type.dart';
import 'package:asset_picker/src/domain/failures/asset_picker_exception.dart';
import 'package:asset_picker/src/infrastructure/providers/scanner_provider.dart';
import 'package:asset_picker/src/infrastructure/scanner/document_scanner_config.dart';
import 'package:document_camera_frame/document_camera_frame.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

/// Real [ScannerProvider] backed by `document_camera_frame`.
///
/// This is the **only** file in the package that references the scanner SDK —
/// the rest of the codebase depends solely on [ScannerProvider], so swapping
/// SDKs never touches feature or picker code.
///
/// It delivers the true scanning experience the camera fallback could not:
/// **auto edge detection, perspective correction, cropping, and JPEG output**.
///
/// ### Why a navigator key
/// Unlike `image_picker` (a self-contained native flow),
/// `document_camera_frame` is a Flutter widget presented on a route. Since
/// [ScannerProvider.scan] is intentionally context-free (it lives behind a
/// domain contract), the provider is given a [GlobalKey] to the app's root
/// navigator so it can present the scanner without a `BuildContext` parameter —
/// keeping the public API unchanged.
///
/// Multi-page is future-ready: [scan] returns a `List<PickedAsset>` and already
/// emits the back side as a second page when captured.
class DocumentCameraFrameScannerProvider implements ScannerProvider {
  const DocumentCameraFrameScannerProvider({
    required GlobalKey<NavigatorState> navigatorKey,
    DocumentScannerConfig config = const DocumentScannerConfig(),
  }) : _navigatorKey = navigatorKey,
       _config = config;

  final GlobalKey<NavigatorState> _navigatorKey;
  final DocumentScannerConfig _config;

  @override
  Future<List<PickedAsset>> scan(AssetPickerOptions options) async {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      throw const AssetSourceUnavailableException(
        AssetSource.scanner,
        message:
            'Document scanner navigator is not attached. Provide a mounted '
            'scannerNavigatorKey via AssetPickerConfig.',
      );
    }

    final effectiveConfig = options.scannerConfig ?? _config;
    final captured = await navigator.push<DocumentCaptureData>(
      MaterialPageRoute<DocumentCaptureData>(
        fullscreenDialog: true,
        builder: (_) => _DocumentScannerHostPage(
          options: options,
          config: effectiveConfig,
        ),
      ),
    );

    if (captured == null) {
      _log('scan cancelled (no capture data)');
      return const [];
    }

    final front = captured.frontImagePath;
    final back = captured.backImagePath;
    final paths = <String>[
      if (front != null && front.isNotEmpty) front,
      if (back != null && back.isNotEmpty) back,
    ];
    final bothSides = options.requireBothSides || _config.requireBothSides;
    _log('capture returned ${paths.length} path(s) (bothSides=$bothSides)');
    if (paths.isEmpty) return const [];

    return [
      for (final path in paths)
        await _toPickedAsset(path, loadBytes: options.loadBytes),
    ];
  }

  Future<PickedAsset> _toPickedAsset(
    String path, {
    required bool loadBytes,
  }) async {
    final file = File(path);
    final exists = file.existsSync();
    final size = exists ? await file.length() : 0;
    _log(
      'materialize: name=${_basename(path)} exists=$exists sizeBytes=$size',
    );
    return PickedAsset(
      name: _basename(path),
      path: path,
      bytes: loadBytes ? await file.readAsBytes() : null,
      // document_camera_frame is configured for JPEG output below.
      mimeType: 'image/jpeg',
      size: size,
      assetType: AssetType.image,
    );
  }

  /// Debug-only trace of the scan → asset handoff (never logs image bytes or
  /// document contents — only path basenames, existence, and sizes). No-op in
  /// release builds.
  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[DocumentScanner] $message');
    }
  }

  String _basename(String path) {
    final slash = path.lastIndexOf('/');
    final backslash = path.lastIndexOf(r'\');
    final cut = slash > backslash ? slash : backslash;
    return cut < 0 ? path : path.substring(cut + 1);
  }
}

/// Internal full-screen host for the [DocumentCameraFrame] widget.
///
/// The widget pops the route itself with a [DocumentCaptureData] on save and
/// `maybePop`s on close, giving the provider a standard `await push` result.
class _DocumentScannerHostPage extends StatelessWidget {
  const _DocumentScannerHostPage({required this.options, required this.config});

  final AssetPickerOptions options;
  final DocumentScannerConfig config;

  @override
  Widget build(BuildContext context) {
    final c = config;
    final primary = c.primaryColor;

    final buttonStyle = DocumentCameraButtonStyle(
      captureFrontButtonText: c.captureFrontButtonText,
      captureBackButtonText: c.captureBackButtonText,
      retakeButtonText: c.retakeButtonText,
      saveButtonText: c.saveButtonText,
      nextButtonText: c.nextButtonText,
      previousButtonText: c.previousButtonText,
    );

    final titleStyle = DocumentCameraTitleStyle(
      title: c.screenTitle != null
          ? Text(
              c.screenTitle!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            )
          : null,
      frontSideTitle: c.frontSideTitle != null
          ? Text(
              c.frontSideTitle!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            )
          : const DocumentCameraTitleStyle().frontSideTitle,
      backSideTitle: c.backSideTitle != null
          ? Text(
              c.backSideTitle!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            )
          : const DocumentCameraTitleStyle().backSideTitle,
    );

    final instructionStyle = DocumentCameraInstructionStyle(
      showInstructionText: c.showInstructionText,
      frontSideInstruction: c.frontSideInstruction,
      backSideInstruction: c.backSideInstruction,
    );

    final sideIndicatorStyle = DocumentCameraSideIndicatorStyle(
      sideIndicatorActiveColor: primary,
      sideIndicatorCompletedColor: primary,
    );

    final progressStyle = DocumentCameraProgressStyle(
      progressIndicatorColor: primary,
    );

    final animationStyle = DocumentCameraAnimationStyle(
      capturingAnimationColor: primary,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return DocumentCameraFrame(
            frameWidth: constraints.maxWidth * c.frameWidthFactor,
            frameHeight: constraints.maxHeight * c.frameHeightFactor,
            showCloseButton: c.showCloseButton,
            requireBothSides: options.requireBothSides || c.requireBothSides,
            enableAutoCapture: c.enableAutoCapture,
            buttonStyle: buttonStyle,
            uiMode: DocumentCameraUIMode.overlay,
            frameStyle: DocumentCameraFrameStyle(
              frameBorder: Border.all(color: primary!, width: 2),
            ),

            titleStyle: titleStyle,
            instructionStyle: instructionStyle,
            sideIndicatorStyle: sideIndicatorStyle,
            progressStyle: progressStyle,
            animationStyle: animationStyle,
            // Output is JPEG (the widget's default) — required by the contract.
            imageQuality: options.enableCompression ? options.imageQuality : 90,
            onCameraError: (_) => Navigator.of(context).maybePop(),
          );
        },
      ),
    );
  }
}
