import 'dart:async';
import 'dart:convert';

import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/ai_ui_renderer.dart';
import 'package:dio/dio.dart';
import 'package:network/network.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/ai_chat_turn_payload.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/sse_frame_parser.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/websocket_ai_chat_event_source.dart'
    show kSanadAccessTokenHeader;
import 'package:sanad_client/src/features/ai_chat/src/domain/ai_chat_event_source.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/ai_interactive_event_source.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/ai_multimodal_event_source.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/entities/ai_outgoing_message.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_attachment_uploader.dart';

/// Abort handle for one turn.
///
/// Created by the transport, honoured by the connector. It exists so the
/// transport can cancel an in-flight request without knowing what HTTP client
/// is underneath — the default connector wires it to a Dio `CancelToken`, a
/// test wires it to nothing at all.
final class AiChatSseCancellation {
  bool _cancelled = false;
  final List<void Function()> _listeners = <void Function()>[];

  /// Whether [cancel] has already run.
  bool get isCancelled => _cancelled;

  /// Runs [callback] when cancelled, or immediately if that already happened.
  void whenCancelled(void Function() callback) {
    if (_cancelled) {
      callback();
      return;
    }
    _listeners.add(callback);
  }

  /// Aborts the turn. Idempotent, and safe to call after completion.
  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    for (final listener in _listeners) {
      listener();
    }
    _listeners.clear();
  }
}

/// One streamed POST, described without a single Dio type.
final class AiChatSseRequest {
  /// Creates the description of one streamed POST.
  const AiChatSseRequest({
    required this.url,
    required this.headers,
    required this.body,
    required this.cancellation,
  });

  /// The absolute streaming endpoint.
  final Uri url;

  /// Includes `Sanad-Access-Token` when there is a session. Never logged.
  final Map<String, String> headers;

  /// The already-encoded JSON body. A `String` rather than a `Map` so a test
  /// can assert on the exact bytes that go on the wire — which is how the
  /// "no credential in the body" rule is proven rather than assumed.
  final String body;

  /// Abort handle for this turn, honoured by the connector.
  final AiChatSseCancellation cancellation;
}

/// The response to an [AiChatSseRequest]: a status and undecoded bytes.
final class AiChatSseResponse {
  /// Creates a response carrying [statusCode] and the undecoded [body].
  const AiChatSseResponse({required this.statusCode, required this.body});

  /// The HTTP status. A non-2xx is classified by code alone — the body is
  /// never read, because it is an internal error document.
  final int statusCode;

  /// Raw bytes, deliberately not decoded by the connector. The transport owns
  /// UTF-8 decoding so that a multi-byte sequence split across two network
  /// chunks is buffered rather than corrupted — a real hazard for Arabic.
  final Stream<List<int>> body;
}

/// A transport-level stall.
///
/// The default connector translates its client's timeout into this, so the
/// source can pick the right message without classifying Dio error types.
final class AiChatSseTimeout implements Exception {
  /// Creates the marker. It carries no detail by design: a timeout needs
  /// no explanation beyond its own occurrence.
  const AiChatSseTimeout();

  @override
  String toString() => 'AiChatSseTimeout';
}

/// Opens one streamed POST. A seam, so a test drives the whole parse pipeline
/// with no network — the same role `AiChatSocketConnector` plays for the
/// WebSocket transport.
typedef AiChatSseConnector =
    Future<AiChatSseResponse> Function(AiChatSseRequest request);

/// How long to wait for the response headers.
const Duration kAiChatSseConnectTimeout = Duration(seconds: 15);

/// How long to wait *between chunks* once streaming has begun.
///
/// An inter-chunk budget in streaming mode, not a total one. The shared 15s
/// `NetworkConfig` default is too tight here: the measured worst
/// time-to-first-token against the dev agent was 9.3s, which leaves almost no
/// headroom. 60s still bounds a hung stream.
const Duration kAiChatSseReceiveTimeout = Duration(seconds: 60);

/// The current real transport: one streamed `POST` per assistant turn.
///
/// This is a *transport*, and nothing more. It does not parse UI, know what a
/// node is, or decide what an action means — it turns SSE frames into
/// [AiChatEvent]s with the very same [AiChatEventCodec] the WebSocket source
/// uses, so the bloc, validator and renderer below it run on an unchanged
/// path.
///
/// ## Why POST + SSE rather than the socket
///
/// Temporary. The agent team cannot currently supply a complete WebSocket
/// contract, and `POST /user-agent/chat/stream` already emits the Protocol v1
/// envelope verbatim. `WebSocketAiChatEventSource` is retained as the
/// reference transport, reachable with `?transport=ws`.
///
/// ## Authentication
///
/// The existing [TokenManager] — the same one the REST stack uses — is the
/// only source of credentials. There is no second token store, no separate
/// login, and no token in any body. The value is read once per turn (so a
/// mid-conversation refresh is picked up), put in the
/// [kSanadAccessTokenHeader] request header, and never logged, never surfaced
/// in an error, and never included in a diagnostic.
///
/// ## Why no interceptors
///
/// The agent is a different host from the REST API and authenticates with a
/// raw `Sanad-Access-Token`, so `AuthInterceptor` is simply the wrong
/// component — and its 401 retry re-issues the request with `Dio.fetch`,
/// which would hand us a second stream while we are consuming the first.
/// `RetryOnTimeoutInterceptor` would duplicate text on a partially consumed
/// stream, and `LoggingInterceptor` has no `ResponseBody` case. None of them
/// are attached.
///
/// ## Failure behaviour
///
/// Total, like everything else in this feature. A malformed frame is dropped
/// with a diagnostic rather than throwing; a truncated stream surfaces as an
/// `error` event so the chat shows something and stays usable. An HTTP error
/// contributes only its status code — the response body is a Pydantic
/// document and never reaches a diagnostic or the user.
class SseAiChatEventSource
    implements
        AiChatEventSource,
        AiMultimodalEventSource,
        AiInteractiveEventSource {
  /// Creates a source that talks to the agent at [url].
  SseAiChatEventSource({
    required this.url,
    required TokenManager tokenManager,
    required this.conversationId,
    AiUiDiagnosticsSink diagnostics = const NoopAiUiDiagnosticsSink(),
    AiChatSseConnector? connector,
    AiAttachmentUploader uploader = const AiUnavailableAttachmentUploader(),
  }) : _tokens = tokenManager,
       _diagnostics = diagnostics,
       _uploader = uploader,
       _injectedConnector = connector,
       // Only built when we are actually going to use it, so a test never
       // constructs an HTTP client it does not need.
       _ownedDio = connector == null ? _buildDio() : null;

  /// The `https://` streaming endpoint.
  final Uri url;

  /// Carried on every turn so the server can keep conversation memory. Stable
  /// for the life of this source, which is one visit to the chat screen.
  final String conversationId;

  final TokenManager _tokens;
  final AiUiDiagnosticsSink _diagnostics;
  final AiAttachmentUploader _uploader;
  final AiChatSseConnector? _injectedConnector;
  final Dio? _ownedDio;

  final StreamController<AiChatEvent> _controller =
      StreamController<AiChatEvent>.broadcast();

  /// The turn in flight. One at a time: a new turn replaces its predecessor.
  StreamSubscription<String>? _subscription;
  AiChatSseCancellation? _cancellation;

  /// Set by [dispose]. Distinguishes a stream we cancelled from one that
  /// failed: only the latter deserves an error bubble.
  bool _disposed = false;

  int _localEventSeq = 0;

  AiChatSseConnector get _connector => _injectedConnector ?? _dioConnector;

  static Dio _buildDio() => Dio(
    BaseOptions(
      connectTimeout: kAiChatSseConnectTimeout,
      receiveTimeout: kAiChatSseReceiveTimeout,
    ),
  );

  @override
  Stream<AiChatEvent> get events => _controller.stream;

  @override
  Future<void> send(String text) => _post(
    AiChatTurnPayload.encode(
      conversationId: conversationId,
      message: text,
    ),
  );

  @override
  Future<void> sendInteraction(
    AiUiInteraction interaction, {
    required String text,
  }) => _post(
    AiChatTurnPayload.encode(
      conversationId: conversationId,
      message: text,
      interaction: interaction,
    ),
  );

  @override
  Future<void> sendMultimodal(AiOutgoingMessage message) async {
    if (_disposed) return;

    // Uploaded first, and the request only made if every file landed: a turn
    // that named an attachment the agent cannot fetch is worse than one that
    // was never sent, because the user is told nothing and the model answers
    // about something it could not read.
    final result = await _uploader.upload(message.attachments);
    if (_disposed) return;

    switch (result) {
      case AiAttachmentUploadFailed(:final failureKey):
        _reportTransport('attachment upload failed');
        _emitTransportError('attachment_upload_failed', failureKey);

      case AiAttachmentsUploaded(:final attachments):
        await _post(
          AiChatTurnPayload.encode(
            conversationId: conversationId,
            message: message.text,
            attachments: attachments,
          ),
        );
    }
  }

  /// Opens one turn with an already-encoded [body].
  ///
  /// Shared by [send] and [sendMultimodal] so the two can never diverge in
  /// headers, cancellation or error handling — the only difference between a
  /// text turn and a multimodal one is the bytes handed in here.
  Future<void> _post(String body) async {
    if (_disposed) return;

    // One request per turn, so a new turn replaces the one in flight rather
    // than racing it and interleaving two messages into one bubble.
    await _endTurn();
    if (_disposed) return;

    final cancellation = AiChatSseCancellation();
    _cancellation = cancellation;

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'text/event-stream',
    };

    // A missing token is not fatal at the transport layer — the server accepts
    // the request either way and the agent simply loses its authenticated
    // tools. Failing here would turn a degraded chat into no chat at all.
    final token = _tokens.accessToken;
    if (token != null && token.isNotEmpty) {
      headers[kSanadAccessTokenHeader] = token;
    }

    final AiChatSseResponse response;
    try {
      response = await _connector(
        AiChatSseRequest(
          url: url,
          headers: headers,
          // Shaped by `AiChatTurnPayload`, which is also where the reason a
          // text turn stays byte-identical to the original two-field body
          // lives. Notably absent: anything resembling a credential — the
          // token is a header, so it can never reach the model's context.
          body: body,
          cancellation: cancellation,
        ),
      );
    } on AiChatSseTimeout {
      if (_stale(cancellation)) return;
      _reportTransport('connect timeout');
      _emitTransportError('timeout', 'ai_chat.transport_timeout');
      return;
    } on Object catch (error) {
      if (_stale(cancellation)) return;
      // The type only. A client error can carry the request URI, and while it
      // never carries a header, interpolating it wholesale is how a leak
      // starts.
      _reportTransport('open failed: ${error.runtimeType}');
      _emitTransportError(
        'connection_failed',
        'ai_chat.transport_connection_failed',
      );
      return;
    }

    if (_stale(cancellation)) return;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      // Status only. The body is an internal error document — Pydantic
      // validation prose on this server — and must not reach the user or a
      // diagnostic.
      _reportTransport('http ${response.statusCode}');
      _emitTransportError(
        'http_${response.statusCode}',
        'ai_chat.transport_request_failed',
      );
      return;
    }

    _listen(response, cancellation);
  }

  /// Subscribes to one turn's byte stream and turns it into events.
  void _listen(AiChatSseResponse response, AiChatSseCancellation cancellation) {
    final parser = SseFrameParser();

    var frameCount = 0;
    var sawMessageStart = false;
    var sawMessageEnd = false;
    var timedOut = false;
    var errored = false;

    _subscription = response.body
        // One streaming decoder for the whole turn. A `Utf8Decoder` used
        // as a stream transformer buffers an incomplete multi-byte
        // sequence across chunks; decoding each chunk on its own would
        // corrupt it.
        .transform(const Utf8Decoder(allowMalformed: true))
        .listen(
          (chunk) {
            if (_stale(cancellation)) return;
            for (final frame in parser.addChunk(chunk)) {
              frameCount++;
              switch (AiChatEventCodec.decode(frame)) {
                case AiChatEventDecoded(:final event):
                  if (event is AiChatMessageStartEvent) {
                    sawMessageStart = true;
                  }
                  if (event is AiChatMessageEndEvent) sawMessageEnd = true;
                  _controller.add(event);
                case AiChatEventIgnored(:final diagnostic):
                  // One bad frame must not tear down a conversation.
                  _diagnostics.report(diagnostic);
              }
            }
          },
          onError: (Object error) {
            if (_stale(cancellation)) return;
            errored = true;
            if (error is AiChatSseTimeout) {
              timedOut = true;
              _reportTransport('receive timeout');
            } else {
              _reportTransport('stream error: ${error.runtimeType}');
            }
          },
          // The error is recorded above and acted on once, in `onDone`, so
          // a stream that errors and then closes yields exactly one event.
          cancelOnError: false,
          onDone: () {
            _subscription = null;
            if (_stale(cancellation)) return;

            if (parser.hasIncompleteFrame) {
              // Per the SSE spec an unterminated frame is discarded. The
              // size is diagnostic; the content is AI prose and is not.
              _reportTransport(
                'discarded incomplete frame '
                '(${parser.incompleteFrameLength} chars)',
              );
            }

            if (timedOut) {
              _emitTransportError('timeout', 'ai_chat.transport_timeout');
              return;
            }

            if (!sawMessageEnd && (sawMessageStart || errored)) {
              // A bubble was opened and never closed. Without this the
              // chat would spin forever, so the transport supplies the
              // signal the server could not — and only here.
              _emitTransportError(
                'stream_interrupted',
                'ai_chat.transport_stream_interrupted',
              );
              return;
            }

            if (frameCount == 0) {
              // Observed live: an empty `message` returns 200
              // `text/event-stream` with no frames at all. Nothing was
              // opened, so nothing is orphaned — report it and emit
              // nothing rather than inventing an event the server never
              // sent.
              _reportTransport('stream closed with no frames');
            }
          },
        );
  }

  /// Whether [cancellation] no longer owns the current turn — because the
  /// source was disposed, or because a newer turn replaced it.
  bool _stale(AiChatSseCancellation cancellation) =>
      _disposed || cancellation.isCancelled || _controller.isClosed;

  /// Cancels the in-flight turn, if any. Safe when there is none.
  Future<void> _endTurn() async {
    _cancellation?.cancel();
    _cancellation = null;

    // Cancelled through the field, not a local: that is what lets the
    // `cancel_subscriptions` lint see the subscription is released. Nothing
    // can assign a new one during the await — `send` awaits `_endTurn` before
    // it opens the next turn.
    await _subscription?.cancel();
    _subscription = null;
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

  void _reportTransport(String detail) {
    _diagnostics.report(
      AiUiDiagnostic(
        code: AiUiDiagnosticCode.malformedPayload,
        path: r'$',
        detail: detail,
      ),
    );
  }

  /// The default connector: a Dio streamed POST with no interceptors.
  Future<AiChatSseResponse> _dioConnector(AiChatSseRequest request) async {
    final dio = _ownedDio!;
    final cancelToken = CancelToken();
    request.cancellation.whenCancelled(cancelToken.cancel);

    try {
      final response = await dio.post<ResponseBody>(
        request.url.toString(),
        data: request.body,
        cancelToken: cancelToken,
        options: Options(
          responseType: ResponseType.stream,
          headers: request.headers,
          // Let a 4xx/5xx arrive as a response rather than a thrown error, so
          // the status can be classified without the body being read at all.
          validateStatus: (_) => true,
        ),
      );

      final body = response.data;
      return AiChatSseResponse(
        statusCode: response.statusCode ?? 0,
        body: body == null
            ? const Stream<List<int>>.empty()
            : _normalizeErrors(body.stream),
      );
    } on DioException catch (error) {
      if (_isTimeout(error)) throw const AiChatSseTimeout();
      rethrow;
    }
  }

  /// Re-labels the client's timeout so the source never classifies Dio types.
  static Stream<List<int>> _normalizeErrors(Stream<List<int>> source) async* {
    try {
      yield* source;
    } on DioException catch (error) {
      if (_isTimeout(error)) throw const AiChatSseTimeout();
      rethrow;
    }
  }

  static bool _isTimeout(DioException error) =>
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.sendTimeout;

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    // Aborts the HTTP request at the socket, so leaving the chat screen does
    // not leave the agent generating into nothing.
    await _endTurn();

    _ownedDio?.close(force: true);

    if (!_controller.isClosed) await _controller.close();
  }
}
