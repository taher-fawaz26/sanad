import 'package:authorization/authorization.dart';
import 'package:core/core.dart';
import 'package:flutter/foundation.dart';

/// Test-only [AuthorizationReader] — register/unregister around each test
/// via [registerFakeAuthorizationReader]/[unregisterFakeAuthorizationReader]
/// so widgets that read `sl<AuthorizationReader>()` (e.g. `BranchListItem`)
/// resolve without needing the full app DI graph.
class FakeAuthorizationReader extends ChangeNotifier
    implements AuthorizationReader {
  FakeAuthorizationReader({
    PermissionSet permissions = PermissionSet.empty,
    bool isResolved = true,
  }) : _permissions = permissions,
       _isResolved = isResolved;

  PermissionSet _permissions;
  bool _isResolved;

  @override
  PermissionSet get permissions => _permissions;

  @override
  bool get isResolved => _isResolved;

  void emit({PermissionSet? permissions, bool? isResolved}) {
    if (permissions != null) _permissions = permissions;
    if (isResolved != null) _isResolved = isResolved;
    notifyListeners();
  }

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

/// Registers a [FakeAuthorizationReader] granting [permissions] and returns
/// it so tests can [FakeAuthorizationReader.emit] a change mid-test. Call
/// [unregisterFakeAuthorizationReader] in `tearDown`.
FakeAuthorizationReader registerFakeAuthorizationReader({
  Iterable<String> permissions = const [],
}) {
  final reader = FakeAuthorizationReader(
    permissions: PermissionSet.from(permissions),
  );
  sl.registerSingleton<AuthorizationReader>(reader);
  return reader;
}

void unregisterFakeAuthorizationReader() {
  if (sl.isRegistered<AuthorizationReader>()) {
    sl.unregister<AuthorizationReader>();
  }
}
