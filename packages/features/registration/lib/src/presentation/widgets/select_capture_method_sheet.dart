import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Capture method chosen from the Identity Verification "Select action" sheet.
enum RegistrationCaptureMethod {
  uploadFile,
  scanOrCapture,
  gallery,
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
    title: 'Select action',
    items: [
      AppActionSheetItem(
        label: 'Upload file',
        leading: leading(AppSvgs.cloudUpload),
        onTap: () => onSelected?.call(RegistrationCaptureMethod.uploadFile),
      ),
      AppActionSheetItem(
        label: 'Scan or capture',
        leading: leading(AppSvgs.registrationIdentityScan),
        onTap: () =>
            onSelected?.call(RegistrationCaptureMethod.scanOrCapture),
      ),
      AppActionSheetItem(
        label: 'Upload from Gallery',
        leading: leading(AppSvgs.registrationGallery),
        onTap: () => onSelected?.call(RegistrationCaptureMethod.gallery),
      ),
    ],
  );
}
