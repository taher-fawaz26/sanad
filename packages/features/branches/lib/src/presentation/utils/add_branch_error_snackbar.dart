import 'package:app_assets/app_assets.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:network/network.dart';

/// Figma error snackbar (`322:9721`) for add-branch save failures.
void showAddBranchErrorSnackbar({
  required BuildContext context,
  required Failure failure,
}) {
  final caption = _resolveErrorCaption(failure);

  showAppSnackbar(
    context: context,
    title: 'branches.add_branch.error_title'.tr(),
    caption: caption,
    color: AppSnackbarColor.error,
    layout: AppSnackbarLayout.fullWidth,
    leadingIcon: AppSvgPicture.asset(
      AppSvgs.alertCircle,
      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
    ),
  );
}

String _resolveErrorCaption(Failure failure) {
  final message = failure.message.trim();
  if (message.isEmpty) {
    return 'branches.add_branch.error_caption'.tr();
  }

  if (message == ErrorMessages.unknown ||
      message == ErrorMessages.serverError) {
    return 'branches.add_branch.error_caption'.tr();
  }

  return message.tr();
}
