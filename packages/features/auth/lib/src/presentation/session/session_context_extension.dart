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
/// context.session.hasPermission('branch:view')
/// ```
///
/// A plain DI lookup — does not depend on [BuildContext] beyond being an
/// ergonomic call site. Use `SessionBuilder`/`SessionSelector` when the UI
/// needs to rebuild on session changes.
extension SessionContextX on BuildContext {
  SessionManager get session => sl<SessionManager>();
}
