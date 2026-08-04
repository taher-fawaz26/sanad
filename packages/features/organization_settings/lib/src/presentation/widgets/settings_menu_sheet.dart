import 'package:account_settings/account_settings.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:organization_settings/src/routes/organization_settings_routes.dart';

/// Settings menu opened from the bottom-nav Settings tab — Figma `3829:5902`.
Future<void> showSettingsMenuSheet(BuildContext context) {
  // Capture the shell context — the sheet runs in a new route.
  final shellContext = context;

  return showAppBottomSheet<void>(
    context: context,
    showDragHandle: false,
    padChild: false,
    child: _SettingsMenuSheetBody(shellContext: shellContext),
  );
}

class _SettingsMenuSheetBody extends StatelessWidget {
  const _SettingsMenuSheetBody({required this.shellContext});

  final BuildContext shellContext;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTableRow(
            title: 'settings.general_settings'.tr(),
            trailing: AppTableTrailing.icon,
            trailingIcon: Icon(
              Icons.chevron_right,
              size: 18,
              color: colors.gray400,
            ),
            onTap: () {
              Navigator.of(context).pop();
              shellContext.go(OrganizationSettingsRoutes.hub);
            },
          ),
          SizedBox(height: AppSpacing.sm),
          AppTableRow(
            title: 'settings.account_settings'.tr(),
            trailing: AppTableTrailing.icon,
            trailingIcon: Icon(
              Icons.chevron_right,
              size: 18,
              color: colors.gray400,
            ),
            onTap: () {
              Navigator.of(context).pop();
              shellContext.push(AccountSettingsRoutes.hub);
            },
          ),
        ],
      ),
    );
  }
}
