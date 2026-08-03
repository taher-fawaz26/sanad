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
/// | 1 | [messages] | `/messages` | FAB action |
/// | 2 | [requests] | `/requests` | FAB action |
/// | 3 | [services] | `/services` | FAB action |
/// | 4 | [settings] | `/settings` | Permanent tab |
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
  bool get isPermanentTab => this == home || this == settings;

  /// Whether this destination is opened from the expandable FAB.
  bool get isFabAction => !isPermanentTab;

  /// Permanent tabs shown in the bottom navigation bar.
  static const List<ProviderBottomNavDestination> permanentTabs = [
    home,
    settings,
  ];

  /// Expandable FAB actions in visual order (Services → Requests → Messages).
  static const List<ProviderBottomNavDestination> fabActions = [
    services,
    requests,
    messages,
  ];

  /// Resolves a shell branch index to its destination, or `null` when out of
  /// range.
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
}
