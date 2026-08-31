import 'package:flutter/foundation.dart';

/// Carries streaming text for the *one* message currently being written.
///
/// This exists to answer the performance requirement directly: a `text_delta`
/// must not rebuild the conversation. Routing deltas through the bloc's state
/// would emit a new state — and therefore a new message list — for every token,
/// which rebuilds the whole `ListView.builder` item set on a hot path.
///
/// Instead the bloc calls [append] and emits *nothing*. Only the active
/// bubble listens here (via `ValueListenableBuilder`), so exactly one widget
/// rebuilds per token. The bloc emits a list-level state only when a message is
/// added, completed, or fails.
class ActiveStreamController extends ValueNotifier<String> {
  /// Starts idle, with no active message.
  ActiveStreamController() : super('');

  String? _messageId;

  /// The message currently streaming, or `null` when idle.
  String? get messageId => _messageId;

  /// Whether [id] is the message currently streaming.
  bool isActive(String id) => _messageId == id;

  /// Begins a new stream, discarding anything left from a previous one.
  void start(String messageId) {
    _messageId = messageId;
    value = '';
  }

  /// Appends a token. No-op when idle.
  void append(String delta) {
    if (_messageId == null || delta.isEmpty) return;
    value = value + delta;
  }

  /// Ends the stream and returns what was accumulated, so the bloc can fall
  /// back to it when `message_end` carries no authoritative text.
  String finish() {
    final accumulated = value;
    _messageId = null;
    value = '';
    return accumulated;
  }
}
