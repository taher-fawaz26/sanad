import 'package:auth/auth.dart';

/// Provider-app routing policy for the individual-vs-organization account
/// split. Deliberately kept in the app (not `packages/auth`) — "which
/// routes are organization-only" is a Provider-app concern, while
/// [SessionManager.isCompany] itself stays a reusable identity fact shared
/// with the client app (which has no organization concept at all).
extension ProviderCapabilities on SessionManager {
  /// Whether the signed-in account is the organization *owner* — grants
  /// the organization setup/KPI hub and, combined with
  /// [isOrganizationTeamMember] for team-member accounts, organization-only
  /// surfaces: branches, workers/team, invitations, provider RBAC. `false`
  /// for individual providers.
  bool get canManageOrganization => isCompany;

  /// Whether the signed-in account may access **owner-only** backend
  /// surfaces — verified live against 8 endpoints that 403 for a worker
  /// holding every catalog permission and 200 for both owner types:
  /// `service-provider/completion`, `service-provider/legal-data`,
  /// `service-provider/working-hours`, `provider-services/overview`,
  /// `service-requests`, `workers/invitations`, `provider/roles`,
  /// `provider/permissions`. The backend defines no permission for any of
  /// them — a worker's role can never grant access no matter how it is
  /// configured, so a persona predicate is the only correct client gate.
  ///
  /// Deliberately [isProvider] (individual **or** organization), not
  /// [canManageOrganization]/[isCompany]: an individual provider owner
  /// returns 200 on all 8 endpoints too (verified live), so gating on
  /// "manages an organization" would incorrectly deny them.
  bool get isProviderOwner => isProvider;

  /// Whether the signed-in account belongs to an organization's team —
  /// either as the owner ([canManageOrganization]) or as one of its
  /// [isWorker]/[isManager] members.
  ///
  /// This is the guard that must gate the *reachability* of
  /// organization-only routes (branches, workers/team, invitations,
  /// provider RBAC) — [canManageOrganization] alone is the wrong predicate
  /// there: a worker or manager's own `userType` is never
  /// `organizationProvider` (that value names the *owner* persona), so
  /// gating on [canManageOrganization]/[isCompany] would redirect every
  /// team member away before the permission guard ever runs. A worker or
  /// manager account exists only because it belongs to an organization —
  /// there is no such thing as an individual provider's worker — so both
  /// personas belong here alongside the owner.
  bool get isOrganizationTeamMember => isWorker || isManager;
}
