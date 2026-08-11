import 'package:auth/src/domain/entities/auth_response_entity.dart';
import 'package:auth/src/session/session_manager.dart';
import 'package:core/core.dart';
import 'package:flutter/widgets.dart';

/// Rebuilds [builder] only when [selector]'s return value changes —
/// `Provider`/`Riverpod`-style scoped selection over the session:
///
/// ```dart
/// SessionSelector<String?>(
///   selector: (session) => session?.accountSettings?.email,
///   builder: (context, email) => Text(email ?? ''),
/// )
/// ```
///
/// Unlike `SessionBuilder`, this does not rebuild on every session mutation —
/// only when the selected [T] value is unequal (`==`) to the previous one.
class SessionSelector<T> extends StatefulWidget {
  const SessionSelector({
    required this.selector,
    required this.builder,
    super.key,
    this.sessionManager,
  });

  final T Function(AuthSessionEntity? session) selector;
  final Widget Function(BuildContext context, T value) builder;

  /// Override for testing. Defaults to the DI-registered singleton.
  final SessionManager? sessionManager;

  @override
  State<SessionSelector<T>> createState() => _SessionSelectorState<T>();
}

class _SessionSelectorState<T> extends State<SessionSelector<T>> {
  late final SessionManager _manager;
  late T _value;

  @override
  void initState() {
    super.initState();
    _manager = widget.sessionManager ?? sl<SessionManager>();
    _value = widget.selector(_manager.current());
    _manager.watch().addListener(_onSessionChanged);
  }

  void _onSessionChanged() {
    final next = widget.selector(_manager.current());
    if (next != _value) {
      setState(() => _value = next);
    }
  }

  @override
  void dispose() {
    _manager.watch().removeListener(_onSessionChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _value);
}
