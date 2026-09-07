// Manual probe: drives the REAL WebSocketAiChatEventSource against the live
// dev agent. Not named *_test.dart, so `flutter test` never picks it up.
//
//   fvm flutter test test/features/ai_chat/live_probe_manual.dart --no-pub
//
// Never prints a credential.
//
// Printing is the entire point of a manual probe — the transcript is the
// evidence — so `avoid_print` is off for this file only.
// ignore_for_file: avoid_print
import 'dart:async';

import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network/network.dart';
import 'package:sanad_client/src/config/app_config.dart';
import 'package:sanad_client/src/features/ai_chat/src/ai_chat_config.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/websocket_ai_chat_event_source.dart';

class _ProbeTokenManager implements TokenManager {
  @override
  String? get accessToken =>
      const String.fromEnvironment('PROBE_TOKEN', defaultValue: 'probe-token');

  @override
  String? get refreshToken => null;

  @override
  Future<void> init() async {}

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {}

  @override
  Future<void> clearTokens() async {}

  @override
  Future<String> refreshAccessToken() async => '';
}

void main() {
  test('live agent round trip', () async {
    final source = WebSocketAiChatEventSource(
      url: Uri.parse(AppConfig.aiAgentSocketUrl),
      tokenManager: _ProbeTokenManager(),
      conversationId: 'probe-live-${DateTime.now().millisecondsSinceEpoch}',
    );

    final done = Completer<void>();
    final events = <AiChatEvent>[];
    final sub = source.events.listen((event) {
      events.add(event);
      print('  <- ${event.type.wire} seq=${event.seq}');
      if (event is AiChatUiEvent ||
          event is AiChatErrorEvent ||
          event is AiChatMessageEndEvent) {
        if (!done.isCompleted) done.complete();
      }
    });

    print('connecting to ${AppConfig.aiAgentSocketUrl} (token attached)');
    await source.send('Find service providers near me');
    await done.future.timeout(const Duration(seconds: 90));
    // Let any trailing frame land.
    await Future<void>.delayed(const Duration(seconds: 6));

    final deltas = events.whereType<AiChatTextDeltaEvent>();
    final text = deltas.map((e) => e.delta).join();
    print('--- accumulated text ---\n$text\n---');

    final validator = AiChatConfig.validator(keepUnsupportedNodes: true);
    for (final ui in events.whereType<AiChatUiEvent>()) {
      final result = validator.validate(ui.payload);
      print(
        'ui: ${result.document?.blocks.length ?? 0} blocks kept, '
        '${result.diagnostics.length} diagnostics '
        '${result.diagnostics.map((d) => d.code.name).toList()}',
      );
      for (final block in result.document?.blocks ?? const <AiUiNode>[]) {
        print('  block: ${block.type?.wire}');
      }
    }

    await sub.cancel();
    await source.dispose();
  }, timeout: const Timeout(Duration(minutes: 3)));
}
