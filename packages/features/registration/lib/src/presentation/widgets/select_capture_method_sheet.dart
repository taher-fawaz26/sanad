import 'package:app_assets/app_assets.dart';
import 'package:asset_picker/asset_picker.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Capture method chosen from the Identity Verification "Select action" sheet.
enum RegistrationCaptureMethod {
  uploadFile,
  scanOrCapture,
  gallery,
}

/// Single-image capture options (camera / gallery) for identity documents.
const _kImageOptions = AssetPickerOptions(
  allowedAssetTypes: [AssetType.image],
);

/// Document options for file uploads — image or PDF.
const _kFileOptions = AssetPickerOptions(
  allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
);

/// Shows the "Select action" sheet, then runs the matching [AssetPicker] call,
/// returning the captured asset (or `null` if the user cancelled at any point).
///
/// Camera / gallery are constrained to images; "Upload file" also accepts PDFs.
Future<PickedAsset?> captureRegistrationDocument(BuildContext context) async {
  // TODO(registration): switch "Scan or capture" to AssetPicker.scanDocument
  // once the app provides a root navigator key for the document scanner.
  RegistrationCaptureMethod? chosen;
  await showSelectCaptureMethodSheet(
    context: context,
    onSelected: (method) => chosen = method,
  );
  if (chosen == null) return null;

  final result = switch (chosen!) {
    RegistrationCaptureMethod.uploadFile =>
      await AssetPicker.pickFile(options: _kFileOptions),
    RegistrationCaptureMethod.scanOrCapture =>
      await AssetPicker.pickCamera(options: _kImageOptions),
    RegistrationCaptureMethod.gallery =>
      await AssetPicker.pickGallery(options: _kImageOptions),
  };
  return result.single;
}

/// Figma `Select action` bottom sheet (`2965:3518`).
///
/// Uses [showAppActionSheet] (scrim + action rows + Cancel).
Future<void> showSelectCaptureMethodSheet({
  required BuildContext context,
  ValueChanged<RegistrationCaptureMethod>? onSelected,
}) {
  Widget leading(String asset) {
    final colors = context.appColors;
    return AppSvgPicture.asset(
      asset,
      width: responsiveDimension(ButtonTokens.iconSize),
      height: responsiveDimension(ButtonTokens.iconSize),
      colorFilter: ColorFilter.mode(colors.textPrimary, BlendMode.srcIn),
    );
  }

  return showAppActionSheet(
    context: context,
    title: 'registration.select_action'.tr(),
    items: [
      AppActionSheetItem(
        label: 'registration.upload_file'.tr(),
        leading: leading(AppSvgs.cloudUpload),
        onTap: () => onSelected?.call(RegistrationCaptureMethod.uploadFile),
      ),
      AppActionSheetItem(
        label: 'registration.scan_capture'.tr(),
        leading: leading(AppSvgs.registrationIdentityScan),
        onTap: () =>
            onSelected?.call(RegistrationCaptureMethod.scanOrCapture),
      ),
      AppActionSheetItem(
        label: 'registration.upload_gallery'.tr(),
        leading: leading(AppSvgs.registrationGallery),
        onTap: () => onSelected?.call(RegistrationCaptureMethod.gallery),
      ),
    ],
  );
}
