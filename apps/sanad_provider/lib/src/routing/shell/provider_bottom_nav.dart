import 'package:app_assets/app_assets.dart';
import 'package:sanad_provider/src/routing/app_routes.dart';

/// Bottom navigation destinations for [MainShell].
///
/// Declaration order is the single source of truth for
/// [StatefulNavigationShell] branch order and shell index conversions.
///
/// | Shell index | Destination | Route | Bar role |
/// |-------------|-------------|-------|----------|
/// | 0 | [home] | `/home` | Permanent tab |
/// | 1 | [messages] | `/messages` | Permanent tab |
/// | 2 | [requests] | `/requests` | Permanent tab |
/// | 3 | [services] | `/services` | Hidden (deep-link only) |
/// | 4 | [settings] | `/settings` | Opens settings menu sheet |
enum ProviderBottomNavDestination {
  home,
  messages,
  requests,
  services,
  settings;

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

  /// Whether this destination is a permanent bottom bar tab.
  bool get isPermanentTab => permanentTabs.contains(this);

  /// Whether tapping this destination opens the settings menu sheet instead of
  /// navigating immediately.
  bool get opensSettingsMenu => this == settings;

  /// Permanent tabs in visual order — Figma `1526:12109`
  /// (Home → Requests → Messages → Settings).
  static const List<ProviderBottomNavDestination> permanentTabs = [
    home,
    requests,
    messages,
    settings,
  ];

  /// Resolves a shell branch index to its destination, or `null` when out of
  /// range.
  static ProviderBottomNavDestination? fromShellBranch(int branchIndex) {
    if (branchIndex < 0 || branchIndex >= values.length) return null;
    return values[branchIndex];
  }

  /// SVG icon asset for this destination (unselected / outline).
  String get iconAsset => switch (this) {
        home => AppNavigationIcons.home,
        messages => AppNavigationIcons.messages,
        requests => AppNavigationIcons.centerAction,
        services => AppNavigationIcons.service,
        settings => AppNavigationIcons.settings,
      };

  /// SVG icon asset when this destination is selected (filled variants).
  String? get selectedIconAsset => switch (this) {
        home => AppNavigationIcons.homeSelected,
        settings => AppNavigationIcons.settingsSelected,
        services => AppNavigationIcons.serviceFilled,
        requests => AppNavigationIcons.requestsFilled,
        messages => AppNavigationIcons.messagesFilled,
      };

  /// Localized label key for this destination.
  String get labelKey => switch (this) {
        home => 'nav.home',
        messages => 'nav.messages',
        requests => 'nav.requests',
        services => 'nav.service',
        settings => 'nav.settings',
      };
}
