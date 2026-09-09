import 'dart:async';

import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/ai_ui_renderer.dart';
import 'package:network/network.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/ai_chat_turn_payload.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/ai_chat_event_source.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/ai_interactive_event_source.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/ai_multimodal_event_source.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/entities/ai_outgoing_message.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_attachment_uploader.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Opens the socket. A seam, so a test can drive the source over an in-memory
/// channel without a network, and so the header-building policy below is
/// testable by inspection rather than by packet capture.
typedef AiChatSocketConnector =
    WebSocketChannel Function(Uri url, Map<String, String> headers);

/// The header the agent server reads the SANAD session from.
///
/// Deliberately a header and not a body field: the token must never travel
/// inside a chat message, where it would end up in the model's context.
const String kSanadAccessTokenHeader = 'Sanad-Access-Token';

/// The production transport: one WebSocket per visit to the chat.
///
/// This is a *transport*, and nothing more. It does not parse UI, know what a
/// node is, or decide what an action means — it turns frames into
/// [AiChatEvent]s with the same codec the mock source's envelopes go through,
/// so the bloc, validator and renderer below it run on exactly the path the
/// prototype proved.
///
/// ## Authentication
///
/// The existing [TokenManager] — the same one the REST stack uses — is the
/// only source of credentials. There is no second token store, no separate
/// login, and no token in any message body. The value is read once per
/// connection attempt, put in the [kSanadAccessTokenHeader] handshake header,
/// and never logged, never surfaced in an error, and never included in a
/// diagnostic.
///
/// ## Failure behaviour
///
/// Total, like everything else in this feature. A malformed frame is dropped
/// with a diagnostic rather than throwing; a dropped connection surfaces as an
/// `error` event so the chat shows something and stays usable, and the next
/// [send] reconnects. Nothing here can tear the conversation down.
class WebSocketAiChatEventSource
    implements
        AiChatEventSource,
        AiMultimodalEventSource,
        AiInteractiveEventSource {
  /// Creates a source that talks to the agent at [url].
  WebSocketAiChatEventSource({
    required this.url,
    required TokenManager tokenManager,
    required this.conversationId,
    AiUiDiagnosticsSink diagnostics = const NoopAiUiDiagnosticsSink(),
    AiChatSocketConnector? connector,
    AiAttachmentUploader uploader = const AiUnavailableAttachmentUploader(),
  }) : _tokens = tokenManager,
       _diagnostics = diagnostics,
       _uploader = uploader,
       _connect = connector ?? _defaultConnector;

  /// The `wss://` endpoint. TLS-only — the server closes a `ws://` handshake.
  final Uri url;

  /// Carried on every turn so the server can keep conversation memory. Stable
  /// for the life of this source, which is one visit to the chat screen.
  final String conversationId;

  final TokenManager _tokens;
  final AiUiDiagnosticsSink _diagnostics;
  final AiAttachmentUploader _uploader;
  final AiChatSocketConnector _connect;

  final StreamController<AiChatEvent> _controller =
      StreamController<AiChatEvent>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;

  /// In flight connection, so two rapid [send]s share one socket instead of
  /// racing and leaving an orphan.
  Future<void>? _connecting;

  /// Set by [dispose]. Distinguishes a socket we closed from one that dropped:
  /// only the latter deserves an error bubble.
  bool _disposed = false;

  int _localEventSeq = 0;

  static WebSocketChannel _defaultConnector(
    Uri url,
    Map<String, String> headers,
  ) => IOWebSocketChannel.connect(url, headers: headers);

  @override
  Stream<AiChatEvent> get events => _controller.stream;

  @override
  Future<void> send(String text) => _frame(
    AiChatTurnPayload.encode(
      conversationId: conversationId,
      message: text,
    ),
  );

  @override
  Future<void> sendInteraction(
    AiUiInteraction interaction, {
    required String text,
  }) => _frame(
    AiChatTurnPayload.encode(
      conversationId: conversationId,
      message: text,
      interaction: interaction,
    ),
  );

  @override
  Future<void> sendMultimodal(AiOutgoingMessage message) async {
    if (_disposed) return;

    // Uploaded first, and the frame only sent if every file landed — the same
    // all-or-nothing rule the SSE transport applies, for the same reason.
    final result = await _uploader.upload(message.attachments);
    if (_disposed) return;

    switch (result) {
      case AiAttachmentUploadFailed(:final failureKey):
        _emitTransportError('attachment_upload_failed', failureKey);
        _report(
          AiUiDiagnosticCode.malformedPayload,
          'attachment upload failed',
        );

      case AiAttachmentsUploaded(:final attachments):
        await _frame(
          AiChatTurnPayload.encode(
            conversationId: conversationId,
            message: message.text,
            attachments: attachments,
          ),
        );
    }
  }

  /// Sends one already-encoded turn, connecting first if needed.
  ///
  /// Shared by [send] and [sendMultimodal] so the two can never diverge — the
  /// only difference between a text turn and a multimodal one is the bytes.
  /// The body is shaped by `AiChatTurnPayload`, which is also where the reason
  /// a text turn stays byte-identical to the original two-field frame lives.
  /// Notably absent from it: anything resembling a credential — the token
  /// lives in the handshake header.
  Future<void> _frame(String body) async {
    if (_disposed) return;

    await _ensureConnected();
    final channel = _channel;
    if (channel == null) return;

    channel.sink.add(body);
  }

  Future<void> _ensureConnected() {
    if (_channel != null) return Future<void>.value();
    return _connecting ??= _openSocket().whenComplete(() => _connecting = null);
  }

  Future<void> _openSocket() async {
    final headers = <String, String>{};

    // A missing token is not fatal at the transport layer — the server accepts
    // the connection either way and the agent simply loses its authenticated
    // tools. Failing the connection here would turn a degraded chat into no
    // chat at all.
    final token = _tokens.accessToken;
    if (token != null && token.isNotEmpty) {
      headers[kSanadAccessTokenHeader] = token;
    }

    final WebSocketChannel channel;
    try {
      channel = _connect(url, headers);
      await channel.ready;
    } on Object catch (error) {
      // `error` can carry the request URI but never a header, so this is safe
      // to surface. Still typed rather than interpolated wholesale.
      _emitTransportError(
        'connection_failed',
        'ai_chat.transport_connection_failed',
      );
      _report(
        AiUiDiagnosticCode.malformedPayload,
        'socket connect failed: ${error.runtimeType}',
      );
      return;
    }

    _channel = channel;
    _subscription = channel.stream.listen(
      _onFrame,
      onError: (Object error) {
        _report(
          AiUiDiagnosticCode.malformedPayload,
          'socket error: ${error.runtimeType}',
        );
      },
      onDone: _onSocketClosed,
      cancelOnError: false,
    );
  }

  void _onFrame(dynamic frame) {
    if (_disposed) return;

    // The server sends text frames. A binary frame is not part of the
    // protocol; dropping it with a diagnostic beats guessing an encoding.
    if (frame is! String) {
      _report(
        AiUiDiagnosticCode.malformedPayload,
        'non-text frame (${frame.runtimeType})',
      );
      return;
    }

    switch (AiChatEventCodec.decode(frame)) {
      case AiChatEventDecoded(:final event):
        _controller.add(event);
      case AiChatEventIgnored(:final diagnostic):
        _diagnostics.report(diagnostic);
    }
  }

  void _onSocketClosed() {
    _subscription = null;
    _channel = null;
    if (_disposed || _controller.isClosed) return;

    // Observed live: sending malformed JSON makes the server kill the socket
    // with no `error` frame at all (close 1006). Without this the chat would
    // simply go quiet, so the transport supplies the missing signal itself —
    // and only here, never inventing an agent-side error for anything else.
    _emitTransportError('connection_closed', 'ai_chat.transport_disconnected');
  }

  void _emitTransportError(String code, String messageKey) {
    if (_controller.isClosed) return;
    _controller.add(
      AiChatErrorEvent(
        eventId: 'local_${DateTime.now().microsecondsSinceEpoch}',
        code: code,
        message: messageKey,
        conversationId: conversationId,
        seq: _localEventSeq++,
      ),
    );
  }

  void _report(AiUiDiagnosticCode code, String detail) {
    _diagnostics.report(
      AiUiDiagnostic(code: code, path: r'$', detail: detail),
    );
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    await _subscription?.cancel();
    _subscription = null;

    // 1000 (normal closure) so the server sees an intentional goodbye rather
    // than a dropped client.
    await _channel?.sink.close(1000);
    _channel = null;

    if (!_controller.isClosed) await _controller.close();
  }
}
