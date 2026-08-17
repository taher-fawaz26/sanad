import 'package:authorization/src/domain/permission_requirement.dart';
import 'package:authorization/src/domain/permission_set.dart';
import 'package:flutter/foundation.dart';

/// Narrow, feature-agnostic read port over the current user's effective
/// authorization. Widgets, the router, and BLoCs depend on this — never on
/// `SessionManager`, `AuthBloc`, or the session cache directly.
///
/// Implemented in `package:auth` (`AuthorizationSignal`) over the existing
/// session snapshot; this package owns no data layer, cache, or network
/// access of its own.
///
/// Extends [Listenable] so a single instance serves three consumers with no
/// adapter: GoRouter's `refreshListenable`, `PermissionGate`'s rebuild
/// trigger, and a plain synchronous read inside a BLoC.
abstract interface class AuthorizationReader implements Listenable {
  /// The current effective permission set.
  PermissionSet get permissions;

  /// `false` until a `/me`-sourced snapshot has been observed for the
  /// current session. Distinguishes "resolved: genuinely has nothing" from
  /// "unresolved: never fetched" — the session-save paths that do not call
  /// `/me` (e.g. worker-invitation acceptance) leave this `false` with an
  /// empty [permissions].
  bool get isResolved;

  /// `false` while [isResolved] is `false`, regardless of [permissions] —
  /// the safe default for widgets and BLoCs, which should treat an
  /// unresolved snapshot as "nothing granted yet" rather than flash a
  /// control that may immediately need to disappear.
  ///
  /// A caller that needs a different policy for the unresolved case (the
  /// router's deep-link/cold-start guard, which must fail OPEN rather than
  /// bounce a legitimate deep link on a timing artifact — see the package
  /// README) should read [permissions] and [isResolved] directly instead of
  /// going through [can]/[canAny]/[canAll]/[satisfies].
  bool can(String action);
  bool canAny(Iterable<String> actions);
  bool canAll(Iterable<String> actions);
  bool satisfies(PermissionRequirement requirement);
}
