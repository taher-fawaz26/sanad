import 'package:asset_picker/asset_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// 10 MB upload ceiling for registration documents.
///
/// Keeps on-device memory in check and prevents accidental huge-file uploads
/// to the OCR API, which typically rejects files above this threshold anyway.
const _kMaxDocumentFileSize = 10 * 1024 * 1024; // 10 MB

/// Options for Emirates ID capture: scanner (front + back), gallery, files.
/// Camera is intentionally excluded — only 3 sources per Figma.
const kRegistrationEmiratesIdOptions = AssetPickerOptions(
  allowCamera: false,
  allowScanner: true,
  allowedAssetTypes: [AssetType.image, AssetType.pdf],
  allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
  requireBothSides: true,
  loadBytes: true,
  maxFileSize: _kMaxDocumentFileSize,
);

/// Options for general document capture (trade licence, single-sided).
/// Camera is intentionally excluded — only 3 sources per Figma.
const kRegistrationDocumentOptions = AssetPickerOptions(
  allowCamera: false,
  allowScanner: true,
  allowedAssetTypes: [AssetType.image, AssetType.pdf],
  allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
  maxFileSize: _kMaxDocumentFileSize,
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
  AssetPickerOptions options = kRegistrationDocumentOptions,
}) async {
  final theme = registrationPickerTheme(context);
  final sheetOptions = options.copyWith(
    sheetTitle: 'registration.select_action'.tr(),
  );

  final source = await showAssetSourceSheet(
    context: context,
    options: sheetOptions,
    theme: theme,
  );
  if (source == null || !context.mounted) return null;

  return pickRegistrationAsset(source, options);
}
