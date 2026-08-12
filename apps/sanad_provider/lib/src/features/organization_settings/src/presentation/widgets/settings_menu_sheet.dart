import 'package:account_settings/account_settings.dart';
import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_provider/src/features/organization_settings/src/routes/organization_settings_routes.dart';
import 'package:sanad_provider/src/routing/provider_capabilities.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

/// Settings menu opened from the bottom-nav Settings tab — Figma `3829:5902`.
Future<void> showSettingsMenuSheet(BuildContext context) {
  // Capture the shell context — the sheet runs in a new route.
  final shellContext = context;

  return SheetNavigator.push<void>(
    context,
    _SettingsMenuSheetBody(shellContext: shellContext),
    settings: const SheetRouteSettings(
      enableDrag: false,
    ),
  );
}

class _SettingsMenuSheetBody extends StatelessWidget {
  const _SettingsMenuSheetBody({required this.shellContext});

  final BuildContext shellContext;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final canManageOrganization = context.session.canManageOrganization;

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
              SheetNavigator.pop(context);
              // Organization providers land on the KPI/setup hub first (it
              // hosts the "General settings" entry point); individual
              // providers have no organization surfaces to see, so they go
              // straight to the General Settings detail screen.
              shellContext.go(
                canManageOrganization
                    ? OrganizationSettingsRoutes.hub
                    : OrganizationSettingsRoutes.general,
              );
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
              SheetNavigator.pop(context);
              shellContext.push(AccountSettingsRoutes.hub);
            },
          ),
        ],
      ),
    );
  }
}
