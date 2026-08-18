import 'package:account_settings/account_settings.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_provider/src/features/organization_settings/src/routes/organization_settings_routes.dart';
import 'package:shared_ui/shared_ui.dart';

/// Settings menu opened from the bottom-nav Settings tab — Figma `3829:5902`.
///
/// Capability-aware (RBAC Phase 7K): the menu items are derived from the
/// signed-in account's persona rather than shown to everyone. General
/// Settings backs onto owner-only backend surfaces
/// (`service-provider/completion`, `service-provider/working-hours`, and
/// `service-provider/legal-data` — RBAC Phase 7 finding F1), so it is
/// hidden entirely for a worker/manager account.
///
/// When only one menu item survives filtering (Account Settings for a
/// worker/manager), the popover is skipped and the tap navigates directly to
/// that destination — no "click through a one-item menu" friction, and no
/// chance of the user briefly seeing an unavailable option.
///
/// Shown as a popover anchored to the tapped tab (pointer triangle included)
/// rather than a bottom sheet. Pass [anchorKey] — the `GlobalKey` attached to
/// the Settings tab tile — to anchor precisely; without it the popover
/// anchors to [context]'s own bounds.
///
/// [isProviderOwner] is resolved by the caller (`MainShell`, the app's
/// composition root for the bottom-nav shell) rather than read here via
/// `sl<SessionManager>()` — this file is a leaf presentation helper and
/// stays free of direct DI/session reads, matching the `isOwner`-threading
/// convention used across Services/Workers/Branches.
void showSettingsMenuSheet(
  BuildContext context, {
  required bool isProviderOwner,
  GlobalKey? anchorKey,
}) {
  final gate = _SettingsMenuGate(isProviderOwner: isProviderOwner);
  final visible = _visibleSettingsMenuItems(gate);

  // Single-item fast path — no "click through a one-item menu" friction.
  // Today this fires for workers/managers (Account Settings is the only
  // survivor), tomorrow it will still fire if any future gate happens to
  // leave one item — the code stays the same.
  if (visible.length == 1) {
    _navigateTo(context, visible.single.action);
    return;
  }

  final colors = context.appColors;
  final typography = context.appTypography;
  final labelStyle = typography.bodyMedium.copyWith(color: colors.gray900);

  final menu = PopupMenu(
    context: context,
    config: MenuConfig.forList(
      itemWidth: 180,
      itemHeight: 52,
      backgroundColor: colors.gray100,
    ),
    items: [
      for (final item in visible)
        MenuItem.forList(
          title: item.titleKey.tr(),
          image: Icon(item.iconData, size: 20, color: colors.gray700),
          textStyle: labelStyle,
          textAlign: TextAlign.left,
          userInfo: item.action,
        ),
    ],
    onClickMenu: (item) =>
        _navigateTo(context, item.menuUserInfo as _SettingsMenuAction),
  );

  if (anchorKey != null) {
    menu.show(widgetKey: anchorKey);
  } else {
    menu.show(rect: _bottomEdgeOf(context));
  }
}

void _navigateTo(BuildContext context, _SettingsMenuAction action) {
  switch (action) {
    case _SettingsMenuAction.general:
      // Both owner personas go to the shell Settings tab, whose route
      // builder renders the persona-appropriate page: the KPI/setup hub
      // for organization providers (it hosts the "General settings" entry
      // point), or General Settings itself for individual providers (who
      // have no organization surfaces). Navigating to the tab — rather
      // than pushing `/settings/general` — keeps the bottom nav visible
      // and avoids stacking a duplicate settings page.
      context.go(OrganizationSettingsRoutes.hub);
    case _SettingsMenuAction.account:
      context.push(AccountSettingsRoutes.hub);
  }
}

enum _SettingsMenuAction { general, account }

/// A single item in the settings popover — one line in the derivation
/// function below, one row in the popover, one route to `context.go`/`push`
/// on tap. Kept internal to this file for now; if a future feature needs
/// to contribute items dynamically, promote to a public type at that time.
class _SettingsMenuItem {
  const _SettingsMenuItem({
    required this.titleKey,
    required this.iconData,
    required this.action,
    required this.gate,
  });

  final String titleKey;
  final IconData iconData;
  final _SettingsMenuAction action;

  /// Returns `true` when the currently signed-in account should see this
  /// entry. Callback shape (not a plain `bool`) so future items can read
  /// finer-grained state — the `PermissionSet` in hand, a business rule,
  /// a feature flag — without changing this file's other rows.
  final bool Function(_SettingsMenuGate gate) gate;
}

/// State supplied to every item's [gate] callback. Today only the persona
/// bit matters; adding more fields (permissions, feature flags) here is
/// the seam intended by Phase 7Q for future owner-only entries like
/// Legal Data / Working Hours / Documents / RBAC without touching each
/// item row.
class _SettingsMenuGate {
  const _SettingsMenuGate({required this.isProviderOwner});

  final bool isProviderOwner;
}

/// The full menu catalog — one line per potential entry, filtered at render
/// time by [_SettingsMenuItem.gate]. Adding a new item (e.g. a dedicated
/// "Legal Data" row when its route lands) is one row here; every other
/// caller stays untouched.
const List<_SettingsMenuItem> _settingsMenuCatalog = [
  _SettingsMenuItem(
    titleKey: 'settings.general_settings',
    iconData: Icons.settings_outlined,
    action: _SettingsMenuAction.general,
    // General Settings hosts three owner-only backend surfaces
    // (`service-provider/completion`, `service-provider/working-hours`,
    // `service-provider/legal-data` — RBAC Phase 7 finding F1), so a
    // worker/manager sees nothing there.
    gate: _isOwner,
  ),
  _SettingsMenuItem(
    titleKey: 'settings.account_settings',
    iconData: Icons.person_outline,
    action: _SettingsMenuAction.account,
    // Backed by `service-provider/profile`, which serves all four provider
    // personas (individual, org, worker, manager). Always available.
    gate: _always,
  ),
];

bool _isOwner(_SettingsMenuGate gate) => gate.isProviderOwner;
bool _always(_SettingsMenuGate gate) => true;

/// The subset of [_settingsMenuCatalog] the signed-in account should see.
/// Exposed for its own widget test in Phase 7Q, and consumed by
/// `showSettingsMenuSheet` above via the same call.
List<_SettingsMenuItem> _visibleSettingsMenuItems(_SettingsMenuGate gate) {
  return [
    for (final item in _settingsMenuCatalog)
      if (item.gate(gate)) item,
  ];
}

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
