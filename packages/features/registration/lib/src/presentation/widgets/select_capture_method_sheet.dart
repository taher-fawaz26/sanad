import 'package:asset_picker/asset_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Registration document picker options: camera, gallery, and file upload.
///
/// Files also accept PDFs; camera and gallery are image-only.
const kRegistrationDocumentOptions = AssetPickerOptions(
  allowedAssetTypes: [AssetType.image],
  allowScanner: true,
  allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
);

/// Runs the matching [AssetPicker] call for [source] (excluding scanner).
///
/// Scanner is handled by the Emirates ID scan flow on Identity Verification;
/// other callers that need scan should use [captureRegistrationDocument].
Future<PickedAsset?> pickRegistrationAsset(AssetSource source) async {
  final result = switch (source) {
    AssetSource.files => await AssetPicker.pickFile(
        options: const AssetPickerOptions(
          allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        ),
      ),
    AssetSource.camera => await AssetPicker.pickCamera(
        options: const AssetPickerOptions(
          allowedAssetTypes: [AssetType.image],
        ),
      ),
    AssetSource.gallery => await AssetPicker.pickGallery(
        options: const AssetPickerOptions(
          allowedAssetTypes: [AssetType.image],
        ),
      ),
    AssetSource.scanner => await AssetPicker.scanDocument(
        options: kRegistrationDocumentOptions,
      ),
  };
  return result.single;
}

/// Shows the asset source sheet, then runs the matching [AssetPicker] call,
/// returning the captured asset (or `null` if the user cancelled at any point).
Future<PickedAsset?> captureRegistrationDocument(BuildContext context) async {
  final theme = AssetPickerTheme.of(context);
  final options = kRegistrationDocumentOptions.copyWith(
    sheetTitle: 'registration.select_action'.tr(),
  );

  final source = await showAssetSourceSheet(
    context: context,
    options: options,
    theme: theme,
  );
  if (source == null) return null;

  return pickRegistrationAsset(source);
}
