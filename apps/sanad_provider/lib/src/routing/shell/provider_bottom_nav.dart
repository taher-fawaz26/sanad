import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sanad_provider/src/routing/app_routes.dart';

/// Bottom navigation destinations for [MainShell].
///
/// Declaration order is the single source of truth for:
/// - [AppBottomNavBar] visual order (indices 0–4)
/// - [StatefulNavigationShell] branch order
/// - Bar index ↔ shell branch conversions ([barIndex], [shellBranchIndex])
///
/// | Bar index | Destination | Route | Tap behavior |
/// |-----------|-------------|-------|----------------|
/// | 0 | [home] | `/home` | Navigate |
/// | 1 | [messages] | `/messages` | Navigate |
/// | 2 | [requests] | `/requests` | Navigate (center FAB) |
/// | 3 | [services] | `/services` | Navigate |
/// | 4 | [settings] | `/settings` | Expandable menu only |
enum ProviderBottomNavDestination {
  home,
  messages,
  requests,
  services,
  settings;

  /// Index in [AppBottomNavBar] (0–4).
  int get barIndex => index;

  /// Index in [StatefulNavigationShell.branches].
  int get shellBranchIndex => index;

  /// GoRouter path for this destination.
  String get route => switch (this) {
        home => AppRoutes.home,
        messages => AppRoutes.messages,
        requests => AppRoutes.requests,
        services => AppRoutes.services,
        settings => AppRoutes.settings,
      };

  /// Whether this destination occupies the center FAB slot (bar index 2).
  bool get isCenterFab => this == requests;

  /// Whether tapping the tab opens the expandable menu instead of navigating.
  bool get opensExpandableMenu => this == settings;

  /// Whether a tab tap should call [StatefulNavigationShell.goBranch].
  bool get navigatesOnTap => !opensExpandableMenu;

  /// Center FAB slot index — always [requests].
  static const int centerFabBarIndex = 2;

  /// Settings tab index — always [settings].
  static const int settingsBarIndex = 4;

  /// Resolves a bar index to its destination, or `null` when out of range.
  static ProviderBottomNavDestination? fromBarIndex(int barIndex) {
    if (barIndex < 0 || barIndex >= values.length) return null;
    return values[barIndex];
  }

  /// Resolves a shell branch index to its destination, or `null` when out of range.
  static ProviderBottomNavDestination? fromShellBranch(int branchIndex) {
    if (branchIndex < 0 || branchIndex >= values.length) return null;
    return values[branchIndex];
  }

  /// SVG icon asset for this destination.
  String get iconAsset => switch (this) {
        home => AppNavigationIcons.home,
        messages => AppNavigationIcons.messages,
        requests => AppNavigationIcons.centerAction,
        services => AppNavigationIcons.service,
        settings => AppNavigationIcons.settings,
      };

  /// Localized label key for this destination.
  String get labelKey => switch (this) {
        home => 'nav.home',
        messages => 'nav.messages',
        requests => 'nav.requests',
        services => 'nav.service',
        settings => 'nav.settings',
      };

  /// Builds the five [AppBottomNavItem]s in visual order for [AppBottomNavBar].
  static List<AppBottomNavItem> items() => [
        for (final destination in values)
          AppBottomNavItem(
            iconAsset: destination.iconAsset,
            label: destination.labelKey.tr(),
          ),
      ];
}
