import 'package:account_settings/account_settings.dart';
import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_provider/src/features/organization_settings/src/routes/organization_settings_routes.dart';
import 'package:sanad_provider/src/routing/provider_capabilities.dart';
import 'package:shared_ui/shared_ui.dart';

/// Settings menu opened from the bottom-nav Settings tab — Figma `3829:5902`.
///
/// Shown as a popover anchored to the tapped tab (pointer triangle included)
/// rather than a bottom sheet. Pass [anchorKey] — the `GlobalKey` attached to
/// the Settings tab tile — to anchor precisely; without it the popover
/// anchors to [context]'s own bounds.
void showSettingsMenuSheet(BuildContext context, {GlobalKey? anchorKey}) {
  final colors = context.appColors;
  final typography = context.appTypography;
  final canManageOrganization = context.session.canManageOrganization;
  final labelStyle = typography.bodyMedium.copyWith(color: colors.gray900);

  final menu = PopupMenu(
    context: context,
    config: MenuConfig.forList(
      itemWidth: 180,
      itemHeight: 52,
      backgroundColor: colors.gray100,
    ),
    items: [
      MenuItem.forList(
        title: 'settings.general_settings'.tr(),
        image: Icon(Icons.settings_outlined, size: 20, color: colors.gray700),
        textStyle: labelStyle,
        textAlign: TextAlign.left,
        userInfo: _SettingsMenuAction.general,
      ),
      MenuItem.forList(
        title: 'settings.account_settings'.tr(),
        image: Icon(Icons.person_outline, size: 20, color: colors.gray700),
        textStyle: labelStyle,
        textAlign: TextAlign.left,
        userInfo: _SettingsMenuAction.account,
      ),
    ],
    onClickMenu: (item) {
      switch (item.menuUserInfo as _SettingsMenuAction) {
        case _SettingsMenuAction.general:
          // Organization providers land on the KPI/setup hub first (it hosts
          // the "General settings" entry point); individual providers have
          // no organization surfaces to see, so they go straight to the
          // General Settings detail screen.
          context.go(
            canManageOrganization
                ? OrganizationSettingsRoutes.hub
                : OrganizationSettingsRoutes.general,
          );
        case _SettingsMenuAction.account:
          context.push(AccountSettingsRoutes.hub);
      }
    },
  );

  if (anchorKey != null) {
    menu.show(widgetKey: anchorKey);
  } else {
    menu.show(rect: _bottomEdgeOf(context));
  }
}

enum _SettingsMenuAction { general, account }

/// A thin anchor rect at the bottom edge of [context]'s bounds — used when no
/// [GlobalKey] is given for the actual trigger. Anchoring to the trigger's
/// full bounds (e.g. a full-screen route) would push the popover below the
/// viewport; a bottom-edge sliver keeps it positioned just above instead.
Rect _bottomEdgeOf(BuildContext context) {
  final box = context.findRenderObject()! as RenderBox;
  final topLeft = box.localToGlobal(Offset.zero);
  return Rect.fromLTWH(
    topLeft.dx,
    topLeft.dy + box.size.height - 1,
    box.size.width,
    1,
  );
}
