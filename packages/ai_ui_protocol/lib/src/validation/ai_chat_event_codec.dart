import 'dart:convert';

import 'package:ai_ui_protocol/src/diagnostics/ai_ui_diagnostic.dart';
import 'package:ai_ui_protocol/src/domain/events/ai_chat_event.dart';
import 'package:ai_ui_protocol/src/validation/ai_ui_limits.dart';

/// Outcome of reading one envelope off the wire.
sealed class AiChatEventDecodeResult {
  const AiChatEventDecodeResult();
}

final class AiChatEventDecoded extends AiChatEventDecodeResult {
  const AiChatEventDecoded(this.event);

  final AiChatEvent event;
}

/// The frame was not usable. The transport should log [diagnostic] and carry
/// on — one bad frame must not tear down a conversation.
final class AiChatEventIgnored extends AiChatEventDecodeResult {
  const AiChatEventIgnored(this.diagnostic);

  final AiUiDiagnostic diagnostic;
}

/// Total parser for the Protocol v1 event envelope.
///
/// Like `AiUiCodec`, nothing here throws. An unknown `type`, a missing field,
/// a truncated frame and outright garbage all come back as
/// [AiChatEventIgnored].
abstract final class AiChatEventCodec {
  static AiChatEventDecodeResult decode(
    String raw, {
    AiUiLimits limits = AiUiLimits.defaults,
  }) {
    if (utf8.encode(raw).length > limits.maxPayloadBytes) {
      return AiChatEventIgnored(
        AiUiDiagnostic(
          code: AiUiDiagnosticCode.limitExceeded,
          path: r'$',
          detail: 'event frame > ${limits.maxPayloadBytes} bytes',
        ),
      );
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return AiChatEventIgnored(
        AiUiDiagnostic(
          code: AiUiDiagnosticCode.malformedPayload,
          path: r'$',
          detail: 'event frame is not valid JSON',
        ),
      );
    }

    if (decoded is! Map<String, dynamic>) {
      return AiChatEventIgnored(
        AiUiDiagnostic(
          code: AiUiDiagnosticCode.malformedPayload,
          path: r'$',
          detail: 'event root is ${decoded.runtimeType}, expected object',
        ),
      );
    }

    return decodeMap(decoded);
  }

  static AiChatEventDecodeResult decodeMap(Map<String, dynamic> json) {
    final eventId = json['eventId'];
    if (eventId is! String || eventId.isEmpty) {
      return _ignore('eventId missing or not a string');
    }

    final rawType = json['type'];
    if (rawType is! String) {
      return _ignore('type missing or not a string');
    }

    final type = AiChatEventType.tryFromWire(rawType);
    if (type == null) {
      // Forward-compatible on purpose: a future event kind (`tool_status`)
      // must be ignorable by an older client, not fatal.
      return _ignore('unknown event type "$rawType"');
    }

    final conversationId = _string(json['conversationId']);
    final messageId = _string(json['messageId']);
    final seq = json['seq'] is int ? json['seq'] as int : 0;
    final createdAt = json['createdAt'] is String
        ? DateTime.tryParse(json['createdAt'] as String)?.toUtc()
        : null;

    final payload = json['payload'] is Map<String, dynamic>
        ? json['payload'] as Map<String, dynamic>
        : const <String, dynamic>{};

    switch (type) {
      case AiChatEventType.messageStart:
        if (messageId == null) return _ignore('message_start needs messageId');
        return AiChatEventDecoded(
          AiChatMessageStartEvent(
            eventId: eventId,
            messageId: messageId,
            conversationId: conversationId,
            seq: seq,
            createdAt: createdAt,
            role: _string(payload['role']) ?? 'assistant',
          ),
        );

      case AiChatEventType.textDelta:
        if (messageId == null) return _ignore('text_delta needs messageId');
        final delta = payload['delta'];
        if (delta is! String) return _ignore('text_delta needs a string delta');
        return AiChatEventDecoded(
          AiChatTextDeltaEvent(
            eventId: eventId,
            messageId: messageId,
            delta: delta,
            conversationId: conversationId,
            seq: seq,
            createdAt: createdAt,
          ),
        );

      case AiChatEventType.messageEnd:
        if (messageId == null) return _ignore('message_end needs messageId');
        return AiChatEventDecoded(
          AiChatMessageEndEvent(
            eventId: eventId,
            messageId: messageId,
            text: _string(payload['text']),
            conversationId: conversationId,
            seq: seq,
            createdAt: createdAt,
          ),
        );

      case AiChatEventType.ui:
        if (messageId == null) return _ignore('ui needs messageId');
        if (payload.isEmpty) return _ignore('ui needs a payload object');
        return AiChatEventDecoded(
          AiChatUiEvent(
            eventId: eventId,
            messageId: messageId,
            payload: payload,
            conversationId: conversationId,
            seq: seq,
            createdAt: createdAt,
          ),
        );

      case AiChatEventType.typing:
        return AiChatEventDecoded(
          AiChatTypingEvent(
            eventId: eventId,
            active: payload['active'] == true,
            conversationId: conversationId,
            messageId: messageId,
            seq: seq,
            createdAt: createdAt,
          ),
        );

      case AiChatEventType.error:
        return AiChatEventDecoded(
          AiChatErrorEvent(
            eventId: eventId,
            code: _string(payload['code']) ?? 'unknown',
            message: _string(payload['message']),
            conversationId: conversationId,
            messageId: messageId,
            seq: seq,
            createdAt: createdAt,
          ),
        );
    }
  }

  static AiChatEventIgnored _ignore(String detail) => AiChatEventIgnored(
    AiUiDiagnostic(
      code: AiUiDiagnosticCode.malformedPayload,
      path: r'$',
      detail: detail,
    ),
  );

  static String? _string(Object? value) =>
      value is String && value.isNotEmpty ? value : null;
}
