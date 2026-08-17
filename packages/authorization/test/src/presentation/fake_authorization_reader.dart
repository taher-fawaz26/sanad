import 'package:authorization/authorization.dart';
import 'package:flutter/foundation.dart';

/// Minimal, test-only [AuthorizationReader]. Mutating [permissions] or
/// [isResolved] does NOT notify by itself — call [emit] to simulate a
/// snapshot change, mirroring how `AuthorizationSignal` only notifies on a
/// genuine decision-relevant change rather than on every mutation.
class FakeAuthorizationReader extends ChangeNotifier
    implements AuthorizationReader {
  FakeAuthorizationReader({
    PermissionSet permissions = PermissionSet.empty,
    bool isResolved = false,
  }) : _permissions = permissions,
       _isResolved = isResolved;

  PermissionSet _permissions;
  bool _isResolved;

  @override
  PermissionSet get permissions => _permissions;

  @override
  bool get isResolved => _isResolved;

  /// Updates state and notifies listeners — simulates a snapshot change.
  void emit({PermissionSet? permissions, bool? isResolved}) {
    if (permissions != null) _permissions = permissions;
    if (isResolved != null) _isResolved = isResolved;
    notifyListeners();
  }

  // Mirrors AuthorizationSignal's contract: these fold in `isResolved` so an
  // unresolved reader denies by default, matching what real callers see.
  @override
  bool can(String action) => _isResolved && _permissions.can(action);

  @override
  bool canAny(Iterable<String> actions) =>
      _isResolved && _permissions.canAny(actions);

  @override
  bool canAll(Iterable<String> actions) =>
      _isResolved && _permissions.canAll(actions);

  @override
  bool satisfies(PermissionRequirement requirement) =>
      _isResolved && requirement.isSatisfiedBy(_permissions);
}
