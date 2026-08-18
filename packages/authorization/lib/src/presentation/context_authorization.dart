import 'package:authorization/src/domain/permission_requirement.dart';
import 'package:authorization/src/reader/authorization_reader.dart';
import 'package:core/core.dart';
import 'package:flutter/widgets.dart';

/// A tap-time authorization decision. Reads the DI-registered
/// [AuthorizationReader] once and returns the current decision — **without**
/// subscribing to future changes.
///
/// Use this from a callback fired at a discrete moment (a button press, a
/// menu tap, `initState` — anywhere the decision doesn't need to stay live).
/// For a decision that must rebuild the tree when the permission set
/// changes, use [PermissionGate] or [PermissionBuilder] instead.
///
/// ```dart
/// // Callback fired at tap time — decision doesn't need to be reactive.
/// void _openMoreActions(BuildContext context) {
///   final canUpdate = context.can(BranchPermissions.update);
///   // ... build the action list ...
/// }
/// ```
///
/// The extension exists so feature packages never have to import
/// `sl<AuthorizationReader>()` or `SessionManager` directly (RBAC Phase 7O
/// rule: leaf widgets and their callbacks never touch DI locators or the
/// auth vertical directly). The parameter name `_` on the [BuildContext]
/// receiver is deliberate — we only need the receiver as a namespace hook;
/// nothing about the context itself matters for this decision, which lets
/// consumers migrate to a widget-tree-scoped reader in the future without
/// changing call sites.
extension AuthorizationOnContext on BuildContext {
  /// Whether the signed-in account may perform [action] right now.
  ///
  /// `false` when the reader has not yet resolved a `/me` snapshot —
  /// consistent with [PermissionBuilder]'s fail-open-on-indeterminate
  /// stance for routing but fail-closed for actions: an unresolved
  /// snapshot must not enable a mutation the user might not actually
  /// have.
  bool can(String action) => sl<AuthorizationReader>().can(action);

  /// Whether the signed-in account holds any of [actions].
  bool canAny(Iterable<String> actions) =>
      sl<AuthorizationReader>().canAny(actions);

  /// Whether the signed-in account holds all of [actions].
  bool canAll(Iterable<String> actions) =>
      sl<AuthorizationReader>().canAll(actions);

  /// Whether the signed-in account satisfies [requirement] — the shape
  /// most useful when the caller already has a composed requirement in
  /// hand (single / any / all).
  bool satisfies(PermissionRequirement requirement) =>
      sl<AuthorizationReader>().satisfies(requirement);
}
