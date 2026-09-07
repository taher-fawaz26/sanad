import 'dart:convert';

import 'package:sanad_client/src/features/ai_chat/src/domain/entities/ai_chat_attachment.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/entities/ai_uploaded_attachment.dart';

/// Builds the body of one user turn.
///
/// The single place the client→agent request is shaped, shared by the SSE and
/// WebSocket transports so the two can never drift.
///
/// ## The shape
///
/// ```json
/// {
///   "conversation_id": "conv_1",
///   "message": "what does this say?",
///   "attachments": [
///     { "id": "68f1…", "url": "https://…" },
///     { "id": "9ab2…", "url": "https://…", "type": "audio",
///       "transcript": "book me a plumber for tomorrow morning" }
///   ]
/// }
/// ```
///
/// ## Rules, and why each one exists
///
/// 1. **`attachments` is omitted when empty**, not sent as `[]`. A text-only
///    turn is therefore byte-identical to the two-field body this endpoint has
///    always received — which is what makes this change additive rather than a
///    protocol bump, and what keeps the existing request-shape tests green.
///    Do not "tidy" this into always emitting the key.
/// 2. **A normal attachment object is exactly `id` and `url`.** The URL is
///    already resolved, so the agent never performs a storage lookup to find a
///    file the client can already point at.
/// 3. **An audio attachment adds `type` and, when there is one, `transcript`.**
///    The transcript rides on the attachment rather than at the top level
///    because `message` belongs to what the user *typed*: a turn can carry both
///    a caption and a voice note, and the two must not collide.
/// 4. **`message` is never empty when the turn has something to say.** With no
///    caption, it takes the transcript. Not decoration — the live agent answers
///    an empty `message` with `200` and zero frames, so a voice-only turn would
///    otherwise be met with silence. It also means a voice note is understood
///    before the backend learns to read `attachments`.
/// 5. **Nothing local ever leaves the device.** No path, file name, MIME type,
///    size, duration or waveform appears here. Those describe a file the agent
///    already has a URL for.
///
/// Returns an encoded `String` rather than a `Map` for the same reason
/// `AiChatSseRequest.body` is one: a test can then assert the exact bytes,
/// which is how "no credential in the body" is proven rather than assumed.
abstract final class AiChatTurnPayload {
  AiChatTurnPayload._();

  /// Wire value of the `type` discriminator on an audio attachment.
  static const String audioType = 'audio';

  /// Encodes one turn.
  ///
  /// [message] is passed through verbatim — trimming already happened in
  /// `AiChatBloc`, and doing it twice would silently change a body the
  /// transport tests pin.
  static String encode({
    required String conversationId,
    required String message,
    List<AiUploadedAttachment> attachments = const [],
  }) {
    final body = <String, dynamic>{
      'conversation_id': conversationId,
      'message': message.isEmpty ? _spokenText(attachments) : message,
    };

    if (attachments.isNotEmpty) {
      body['attachments'] = [for (final a in attachments) _attachment(a)];
    }

    return jsonEncode(body);
  }

  static Map<String, dynamic> _attachment(AiUploadedAttachment attachment) {
    final json = <String, dynamic>{
      'id': attachment.mediaId,
      'url': attachment.url,
    };

    final source = attachment.source;
    if (source is AiAudioAttachment) {
      json['type'] = audioType;
      if (source.transcript.isNotEmpty) json['transcript'] = source.transcript;
    }

    return json;
  }

  /// The transcripts of every voice note in the turn, in order.
  ///
  /// Used only to fill an otherwise-empty [encode]'s `message`. More than one
  /// voice note per turn is unreachable today — the composer's recording state
  /// occupies it until the take is sent or discarded — but joining is still the
  /// honest answer if that ever changes.
  static String _spokenText(List<AiUploadedAttachment> attachments) => [
    for (final a in attachments)
      if (a.source case final AiAudioAttachment audio)
        if (audio.transcript.isNotEmpty) audio.transcript,
  ].join(' ');
}
