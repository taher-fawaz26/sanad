import 'package:auth/src/session/session_manager.dart';
import 'package:core/core.dart';
import 'package:flutter/widgets.dart';

/// `context.session` instead of `sl<SessionManager>()` everywhere.
///
/// ```dart
/// context.session.current
/// context.session.user
/// context.session.profile
/// context.session.accountSettings
/// context.session.permissions
/// context.session.displayName
/// ```
///
/// A plain DI lookup — does not depend on [BuildContext] beyond being an
/// ergonomic call site. Use `SessionBuilder`/`SessionSelector` when the UI
/// needs to rebuild on session changes.
///
/// Authorization checks do NOT go through here — use
/// `package:authorization`'s `AuthorizationReader`/`PermissionGate` instead,
/// via `sl<AuthorizationReader>()`. `SessionManager` no longer exposes a
/// permission-check API (its previous `hasPermission` matched the literal
/// string `'*'` only, so it silently denied the backend's actual `provider:*`
/// wildcard for every provider owner — it had zero production callers and
/// was removed rather than fixed in place).
extension SessionContextX on BuildContext {
  SessionManager get session => sl<SessionManager>();
}
