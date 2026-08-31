import 'package:equatable/equatable.dart';

/// Event kinds in the Protocol v1 envelope.
///
/// `tool_status` is reserved in the specification and deliberately not
/// implemented — an unknown `type` is ignored rather than treated as an error,
/// so the backend can start emitting it before clients understand it.
enum AiChatEventType {
  messageStart('message_start'),
  textDelta('text_delta'),
  messageEnd('message_end'),
  ui('ui'),
  typing('typing'),
  error('error')
  ;

  const AiChatEventType(this.wire);

  final String wire;

  static AiChatEventType? tryFromWire(String value) {
    for (final candidate in values) {
      if (candidate.wire == value) return candidate;
    }
    return null;
  }
}

/// One message on the wire, independent of *which* wire.
///
/// Nothing here knows about WebSockets, SSE or the mock source. That is the
/// point: swapping the transport must not touch the event model, the parser,
/// or anything downstream of them.
sealed class AiChatEvent extends Equatable {
  const AiChatEvent({
    required this.eventId,
    this.conversationId,
    this.messageId,
    this.seq = 0,
    this.createdAt,
  });

  final String eventId;
  final String? conversationId;

  /// The message this event belongs to. Absent only for conversation-level
  /// events such as `typing`.
  final String? messageId;

  /// Monotonic per conversation. Lets a consumer detect gaps and reordering
  /// without the transport having to guarantee ordering.
  final int seq;

  final DateTime? createdAt;

  AiChatEventType get type;

  List<Object?> get baseProps => [
    eventId,
    conversationId,
    messageId,
    seq,
    createdAt,
  ];

  Map<String, dynamic> baseJson() => <String, dynamic>{
    'eventId': eventId,
    if (conversationId != null) 'conversationId': conversationId,
    if (messageId != null) 'messageId': messageId,
    'seq': seq,
    'type': type.wire,
    if (createdAt != null) 'createdAt': createdAt!.toUtc().toIso8601String(),
  };

  Map<String, dynamic> toJson();
}

/// Opens an assistant message. The client creates an empty bubble.
final class AiChatMessageStartEvent extends AiChatEvent {
  const AiChatMessageStartEvent({
    required super.eventId,
    required String super.messageId,
    super.conversationId,
    super.seq,
    super.createdAt,
    this.role = 'assistant',
  });

  final String role;

  @override
  AiChatEventType get type => AiChatEventType.messageStart;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(),
    'payload': <String, dynamic>{'role': role},
  };

  @override
  List<Object?> get props => [...baseProps, role];
}

/// Appends to the *active* message only.
///
/// Consumers must not rebuild the conversation for a delta — see the
/// `ActiveStreamController` seam in the chat feature.
final class AiChatTextDeltaEvent extends AiChatEvent {
  const AiChatTextDeltaEvent({
    required super.eventId,
    required String super.messageId,
    required this.delta,
    super.conversationId,
    super.seq,
    super.createdAt,
  });

  final String delta;

  @override
  AiChatEventType get type => AiChatEventType.textDelta;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(),
    'payload': <String, dynamic>{'delta': delta},
  };

  @override
  List<Object?> get props => [...baseProps, delta];
}

/// Closes a message. [text] is authoritative and replaces whatever the deltas
/// accumulated, so a dropped delta cannot leave a permanently wrong bubble.
final class AiChatMessageEndEvent extends AiChatEvent {
  const AiChatMessageEndEvent({
    required super.eventId,
    required String super.messageId,
    this.text,
    super.conversationId,
    super.seq,
    super.createdAt,
  });

  final String? text;

  @override
  AiChatEventType get type => AiChatEventType.messageEnd;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(),
    'payload': <String, dynamic>{if (text != null) 'text': text},
  };

  @override
  List<Object?> get props => [...baseProps, text];
}

/// Carries a structured-UI payload for [messageId].
///
/// [payload] is the *raw* `{schemaVersion, blocks}` object. It is deliberately
/// not validated here: validation needs host configuration (URL policy, the
/// action registry's real key set, known asset ids) that the envelope layer
/// has no business knowing. The consumer runs `AiUiValidator` once, at
/// ingestion, and stores the resulting document.
final class AiChatUiEvent extends AiChatEvent {
  const AiChatUiEvent({
    required super.eventId,
    required String super.messageId,
    required this.payload,
    super.conversationId,
    super.seq,
    super.createdAt,
  });

  final Map<String, dynamic> payload;

  @override
  AiChatEventType get type => AiChatEventType.ui;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(),
    'payload': payload,
  };

  @override
  List<Object?> get props => [...baseProps, payload];
}

final class AiChatTypingEvent extends AiChatEvent {
  const AiChatTypingEvent({
    required super.eventId,
    required this.active,
    super.conversationId,
    super.messageId,
    super.seq,
    super.createdAt,
  });

  final bool active;

  @override
  AiChatEventType get type => AiChatEventType.typing;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(),
    'payload': <String, dynamic>{'active': active},
  };

  @override
  List<Object?> get props => [...baseProps, active];
}

/// An agent-side failure, rendered as an error bubble.
///
/// [message] is already localized prose from the agent, on the same terms as
/// any other text in the protocol.
final class AiChatErrorEvent extends AiChatEvent {
  const AiChatErrorEvent({
    required super.eventId,
    required this.code,
    this.message,
    super.conversationId,
    super.messageId,
    super.seq,
    super.createdAt,
  });

  final String code;
  final String? message;

  @override
  AiChatEventType get type => AiChatEventType.error;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(),
    'payload': <String, dynamic>{
      'code': code,
      if (message != null) 'message': message,
    },
  };

  @override
  List<Object?> get props => [...baseProps, code, message];
}
