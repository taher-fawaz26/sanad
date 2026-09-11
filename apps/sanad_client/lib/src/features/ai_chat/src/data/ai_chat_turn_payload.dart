import 'dart:convert';

import 'package:ai_ui_protocol/ai_ui_protocol.dart';
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
///     { "id": "9ab2…", "url": "https://…" }
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
/// 2. **An attachment object is exactly `id` and `url`.** Every attachment,
///    with no discriminator and no per-type extras. The URL is already
///    resolved, so the agent never performs a storage lookup to find a file
///    the client can already point at.
/// 3. **There is no audio attachment, and no client can produce one.** AI Chat
///    supports Speech-to-Text as a voice input method: speech is recognised
///    into text on the device and submitted as an ordinary text turn, so it
///    arrives in `message` like anything the user typed. Recorded audio is not
///    sent to the agent. Do not reintroduce a `type` or `transcript` field
///    here.
/// 4. **`message` is passed through as given.** It is empty only for a turn
///    that genuinely has no words — an image or document with no caption.
/// 5. **Nothing local ever leaves the device.** No path, file name, MIME type
///    or size appears here. Those describe a file the agent already has a URL
///    for.
/// 6. **`interaction` is omitted unless the turn *is* one**, for the same
///    reason as `attachments`. When it is present, `message` still carries the
///    sentence the agent's own template produced — so a backend that has not
///    learned to read `interaction` receives exactly the body a tapped card has
///    always sent, and the structured half is pure addition.
///
/// Returns an encoded `String` rather than a `Map` for the same reason
/// `AiChatSseRequest.body` is one: a test can then assert the exact bytes,
/// which is how "no credential in the body" is proven rather than assumed.
abstract final class AiChatTurnPayload {
  AiChatTurnPayload._();

  /// Encodes one turn.
  ///
  /// [message] is passed through verbatim — trimming already happened in
  /// `AiChatBloc`, and doing it twice would silently change a body the
  /// transport tests pin.
  static String encode({
    required String conversationId,
    required String message,
    List<AiUploadedAttachment> attachments = const [],
    AiUiInteraction? interaction,
  }) {
    final body = <String, dynamic>{
      'conversation_id': conversationId,
      'message': message,
    };

    if (attachments.isNotEmpty) {
      body['attachments'] = [for (final a in attachments) _attachment(a)];
    }

    if (interaction != null) {
      body['interaction'] = AiUiInteractionCodec.encodeMap(interaction);
    }

    return jsonEncode(body);
  }

  /// One attachment, as exactly the two fields rule 2 allows.
  static Map<String, dynamic> _attachment(AiUploadedAttachment attachment) => {
    'id': attachment.mediaId,
    'url': attachment.url,
  };
}
