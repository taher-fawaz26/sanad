import 'package:flutter/widgets.dart';

/// Presenter port for the "Roles" tab pane shown inside the Workers screen's
/// segmented control (Team / Invitations / Roles).
///
/// The roles UI lives in `provider_rbac`, which depends on `workers` — not
/// the other way around. This port lets `workers_page` render the roles pane
/// inline (like the Team and Invitations panes) without importing
/// `provider_rbac`; the implementation is registered through the service
/// locator, inverting the dependency (mirrors [WorkerRoleAssigner]).
abstract class WorkerRolesTabView {
  /// Builds the self-contained roles pane (its own BLoCs, search, list, and
  /// add action). No app bar or segmented control — the Workers screen owns
  /// that chrome.
  Widget build();
}
