import 'package:authorization/authorization.dart';
import 'package:sanad_provider/src/features/requests/requests.dart';
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
/// Services and Requests each carry a real gate, because each is backed by a
/// permission-controlled endpoint — `GET /provider-services` and
/// `GET /provider/requests`. Home and Messages are still placeholder pages
/// with no backend fetch, and Settings opens a menu sheet rather than
/// navigating; none of them have anything to gate.
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
    // The workspace is entirely `GET /provider/requests`; without the view
    // permission every screen behind this tab answers 403.
    ProviderBottomNavDestination.requests => reader.can(
      ClientRequestPermissions.view,
    ),
    _ => true,
  };
}
