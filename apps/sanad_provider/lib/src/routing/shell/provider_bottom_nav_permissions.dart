import 'package:authorization/authorization.dart';
import 'package:sanad_provider/src/routing/shell/provider_bottom_nav.dart';
import 'package:services/services.dart';

/// Which of [ProviderBottomNavDestination.permanentTabs] the signed-in
/// account may actually see, derived from [reader]'s effective permissions.
///
/// `permanentTabs` itself stays the full, fixed list, and
/// [ProviderBottomNavDestination.shellBranchIndex] stays static —
/// `StatefulShellRoute` requires a stable branch count — this function only
/// decides which of those branches get a rendered bottom-bar tile.
/// `MainShell` falls back to highlighting Home if the currently active
/// branch is ever one that got filtered out here (e.g. a permission was
/// revoked while the user was already on that tab).
///
/// Today only Services carries a real gate — `provider:provider-service:view`
/// — since it is the only permanent tab actually backed by a
/// permission-controlled endpoint (`GET /provider-services`). Home,
/// Messages, and Requests are placeholder pages with no backend fetch yet,
/// and Settings opens a menu sheet rather than navigating; none of them
/// have anything to gate.
List<ProviderBottomNavDestination> visibleBottomNavTabs(
  AuthorizationReader reader,
) {
  return [
    for (final tab in ProviderBottomNavDestination.permanentTabs)
      if (_isVisible(tab, reader)) tab,
  ];
}

bool _isVisible(ProviderBottomNavDestination tab, AuthorizationReader reader) {
  return switch (tab) {
    ProviderBottomNavDestination.services => reader.can(
      ServicePermissions.providerServiceView,
    ),
    _ => true,
  };
}
