import 'package:asset_picker/asset_picker.dart';
import 'package:core/core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Scanner presentation for Emirates ID: two-sided, localized titles.
DocumentScannerConfig emiratesIdScannerConfig() => DocumentScannerConfig(
  screenTitle: 'registration.scan_emirates_id_title'.tr(),
  frontSideTitle: 'registration.scan_front_side'.tr(),
  backSideTitle: 'registration.scan_back_side'.tr(),
  frontSideInstruction: 'registration.scan_front_instruction'.tr(),
  backSideInstruction: 'registration.scan_back_instruction'.tr(),
  retakeButtonText: 'registration.scan_retake'.tr(),
  saveButtonText: 'registration.scan_continue'.tr(),
  showInstructionText: true,
  primaryColor: const Color(0xFF26A68C),
);

/// Scanner presentation for Trade License: single-document, no front/back.
DocumentScannerConfig tradeLicenseScannerConfig() => DocumentScannerConfig(
  screenTitle: 'registration.scan_trade_license_title'.tr(),
  showInstructionText: true,
  primaryColor: const Color(0xFF26A68C),
  saveButtonText: 'registration.scan_continue'.tr(),
);

/// Registration document upload ceiling — the app-wide `FileSizePolicy`
/// maximum (5 MB). Also keeps on-device memory in check.
const int _kMaxDocumentFileSize = FileSizePolicy.maxBytes;

/// Base options for Emirates ID capture: **scan-only, one side per scan**.
///
/// Gallery/file upload are intentionally disabled for Emirates ID — the only
/// user action is "Scan Emirates ID" (the in-app document scanner), whose
/// captured image is then validated as a real Emirates ID before it enters
/// the upload pipeline (see `document_validation`'s
/// `DocumentTypeValidator`). This is a product decision, not a scanner
/// limitation.
///
/// `requireBothSides` is **false** on purpose: the identity screen presents
/// the front and back as two independent slots, each with its own scan/upload
/// action, so a single scan session must return exactly one image.
const _kEmiratesIdBaseOptions = AssetPickerOptions(
  allowCamera: false,
  allowGallery: false,
  allowFiles: false,
  allowScanner: true,
  allowedAssetTypes: [AssetType.image, AssetType.pdf],
  allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
  loadBytes: true,
  maxFileSize: _kMaxDocumentFileSize,
);

/// Base options for general document capture (trade licence, single-sided).
/// Camera is intentionally excluded — only 3 sources per Figma.
const _kDocumentBaseOptions = AssetPickerOptions(
  allowCamera: false,
  allowScanner: true,
  allowedAssetTypes: [AssetType.image, AssetType.pdf],
  allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
  maxFileSize: _kMaxDocumentFileSize,
);

/// Emirates ID capture options with localized scanner config applied.
AssetPickerOptions get kRegistrationEmiratesIdOptions =>
    _kEmiratesIdBaseOptions.copyWith(
      scannerConfig: emiratesIdScannerConfig(),
    );

/// Trade licence capture options with localized scanner config applied.
AssetPickerOptions get kRegistrationDocumentOptions =>
    _kDocumentBaseOptions.copyWith(
      scannerConfig: tradeLicenseScannerConfig(),
    );

/// Builds an [AssetPickerTheme] with registration-specific bottom-sheet labels.
AssetPickerTheme registrationPickerTheme(BuildContext context) =>
    AssetPickerTheme.of(
      context,
      texts: AssetPickerTexts(
        sheetTitle: 'registration.select_action'.tr(),
        scannerLabel: 'registration.scan_capture'.tr(),
        scannerDescription: '',
        galleryLabel: 'registration.upload_gallery'.tr(),
        galleryDescription: '',
        filesLabel: 'registration.upload_file'.tr(),
        filesDescription: '',
      ),
    );

/// Runs the matching [AssetPicker] call for [source].
///
/// For scanner, [options] must have [AssetPickerOptions.requireBothSides] set
/// as needed — the caller controls this. Returns `null` on cancellation.
Future<AssetPickerResult?> pickRegistrationAsset(
  AssetSource source,
  AssetPickerOptions options,
) async {
  final result = switch (source) {
    AssetSource.files => await AssetPicker.pickFile(
      options: options.copyWith(allowMultiple: true, maxSelection: 2),
    ),
    AssetSource.camera => await AssetPicker.pickCamera(
      options: options,
    ),
    AssetSource.gallery => await AssetPicker.pickGallery(
      options: options.copyWith(allowMultiple: true, maxSelection: 2),
    ),
    AssetSource.scanner => await AssetPicker.scanDocument(
      options: options,
    ),
  };
  return result.cancelled ? null : result;
}

/// Shows the asset source sheet and returns the picked assets, or `null` if
/// the user cancelled at any point.
Future<AssetPickerResult?> captureRegistrationDocument(
  BuildContext context, {
  AssetPickerOptions? options,
}) async {
  final effectiveOptions = options ?? kRegistrationDocumentOptions;
  final theme = registrationPickerTheme(context);
  final sheetOptions = effectiveOptions.copyWith(
    sheetTitle: 'registration.select_action'.tr(),
  );

  final source = await showAssetSourceSheet(
    context: context,
    options: sheetOptions,
    theme: theme,
  );
  if (source == null || !context.mounted) return null;

  return pickRegistrationAsset(source, effectiveOptions);
}
