import 'package:auth/auth.dart';

/// Provider-app routing policy for the individual-vs-organization account
/// split. Deliberately kept in the app (not `packages/auth`) — "which
/// routes are organization-only" is a Provider-app concern, while
/// [SessionManager.isCompany] itself stays a reusable identity fact shared
/// with the client app (which has no organization concept at all).
extension ProviderCapabilities on SessionManager {
  /// Whether the signed-in account may access organization-only surfaces:
  /// branches, workers/team, invitations, provider RBAC, and the
  /// organization setup/KPI hub. `false` for individual providers.
  bool get canManageOrganization => isCompany;
}
