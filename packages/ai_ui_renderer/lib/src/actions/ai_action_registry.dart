import 'dart:async';

import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:flutter/widgets.dart';

/// Executes one action type on the app's behalf.
///
/// The agent *requests* intent; a handler decides what actually happens,
/// including whether the user is allowed to do it. Authorization belongs here,
/// never in the payload.
abstract class AiActionHandler {
  const AiActionHandler();

  AiUiActionType get type;

  FutureOr<void> handle(BuildContext context, AiUiAction action);
}

/// The compile-time allowlist of things an AI payload can ask for.
///
/// This is a `Map<AiUiActionType, AiActionHandler>` populated at DI time — not
/// a string-to-method lookup, not reflection, not `eval`. An action with no
/// registered handler is unreachable: [supportedTypes] is handed to
/// `AiUiValidator`, which drops the owning node before rendering, so a dead
/// control never appears.
final class AiActionRegistry {
  AiActionRegistry([Iterable<AiActionHandler> handlers = const []]) {
    handlers.forEach(register);
  }

  final Map<AiUiActionType, AiActionHandler> _handlers = {};

  void register(AiActionHandler handler) {
    _handlers[handler.type] = handler;
  }

  /// Pass this to `AiUiValidator.supportedActions`.
  Set<AiUiActionType> get supportedTypes => _handlers.keys.toSet();

  bool supports(AiUiActionType type) => _handlers.containsKey(type);

  /// Runs the handler for [action], or does nothing if there is none.
  ///
  /// Returning quietly rather than throwing matters: a payload validated
  /// against a different registry (a cached message, a hot reload) must not be
  /// able to crash the chat by tapping an old button.
  Future<void> dispatch(BuildContext context, AiUiAction action) async {
    final handler = _handlers[action.type];
    if (handler == null) return;
    await handler.handle(context, action);
  }
}
