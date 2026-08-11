import 'package:auth/src/domain/entities/auth_response_entity.dart';
import 'package:auth/src/session/session_manager.dart';
import 'package:core/core.dart';
import 'package:flutter/widgets.dart';

/// Rebuilds [builder] whenever the authenticated session changes.
///
/// Thin wrapper over `SessionManager.watch()` so widgets never touch
/// [ValueListenableBuilder] directly:
///
/// ```dart
/// SessionBuilder(
///   builder: (context, session) => Text(session?.user.email ?? 'Guest'),
/// )
/// ```
///
/// Rebuilds on every session mutation (save/update/clear/restore). For a
/// rebuild scoped to a single derived value, use `SessionSelector` instead.
class SessionBuilder extends StatelessWidget {
  const SessionBuilder({required this.builder, super.key, this.sessionManager});

  final Widget Function(BuildContext context, AuthSessionEntity? session)
  builder;

  /// Override for testing. Defaults to the DI-registered singleton.
  final SessionManager? sessionManager;

  @override
  Widget build(BuildContext context) {
    final manager = sessionManager ?? sl<SessionManager>();
    return ValueListenableBuilder<AuthSessionEntity?>(
      valueListenable: manager.watch(),
      builder: (context, session, _) => builder(context, session),
    );
  }
}
