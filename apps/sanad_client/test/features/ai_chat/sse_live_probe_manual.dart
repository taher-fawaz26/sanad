// Manual probe: drives the REAL SseAiChatEventSource against the live dev
// agent. Not named *_test.dart, so `flutter test` never picks it up.
//
//   fvm flutter test test/features/ai_chat/sse_live_probe_manual.dart --no-pub
//   fvm flutter test test/features/ai_chat/sse_live_probe_manual.dart --no-pub \
//     --dart-define=PROBE_TOKEN=<a dev token>
//
// Never prints a credential. It prints the token's *length* only, which is
// enough to tell "attached" from "absent" without putting the value anywhere.
//
// It covers the checklist the transport swap is verified against: streaming,
// server-side memory across turns on one conversation id, and Arabic.
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
import 'package:sanad_client/src/features/ai_chat/src/data/sse_ai_chat_event_source.dart';

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

/// Runs one turn and returns everything the agent sent for it.
Future<List<AiChatEvent>> turn(
  SseAiChatEventSource source,
  Stream<AiChatEvent> events,
  String message,
) async {
  final collected = <AiChatEvent>[];
  final done = Completer<void>();

  final sub = events.listen((event) {
    collected.add(event);
    if (event is AiChatMessageEndEvent || event is AiChatErrorEvent) {
      if (!done.isCompleted) done.complete();
    }
  });

  print('\n-> $message');
  await source.send(message);
  await done.future.timeout(const Duration(seconds: 120));
  // Let a trailing `ui` frame land, if the agent ever starts sending one.
  await Future<void>.delayed(const Duration(seconds: 3));
  await sub.cancel();

  final types = collected.map((e) => e.type.wire).toSet().toList()..sort();
  final deltas = collected.whereType<AiChatTextDeltaEvent>().length;
  print('   <- ${collected.length} events, $deltas deltas, types=$types');
  return collected;
}

String finalTextOf(List<AiChatEvent> events) =>
    events.whereType<AiChatMessageEndEvent>().lastOrNull?.text ??
    events.whereType<AiChatTextDeltaEvent>().map((e) => e.delta).join();

void main() {
  test(
    'live agent round trip over POST + SSE',
    () async {
      final token = _ProbeTokenManager().accessToken ?? '';
      print('endpoint: ${AppConfig.aiAgentStreamUrl}');
      final tokenState = token.isEmpty
          ? 'ABSENT'
          : 'attached (${token.length} chars)';
      print('token: $tokenState');

      // One id for the whole probe, which is what makes the memory check real.
      final conversationId =
          'probe-sse-${DateTime.now().millisecondsSinceEpoch}';
      print('conversationId: $conversationId');

      final source = SseAiChatEventSource(
        url: Uri.parse(AppConfig.aiAgentStreamUrl),
        tokenManager: _ProbeTokenManager(),
        conversationId: conversationId,
      );
      final events = source.events.asBroadcastStream();

      // 1. English, streaming.
      final first = await turn(
        source,
        events,
        'My name is Taher and I live in Dubai. What services do you offer?',
      );
      print('   text: ${finalTextOf(first)}');
      expect(
        first.whereType<AiChatTextDeltaEvent>(),
        isNotEmpty,
        reason: 'the reply should stream as deltas, not arrive in one lump',
      );

      // 2. Same conversation id — does the server remember turn 1?
      final second = await turn(
        source,
        events,
        'What is my name and which city did I say I live in?',
      );
      final recalled = finalTextOf(second);
      print('   text: $recalled');
      final remembered =
          recalled.contains('Taher') && recalled.contains('Dubai');
      final memory = remembered ? 'recalled turn 1' : 'NOT recalled';
      print('   MEMORY: $memory');

      // 3. Arabic, to prove no mojibake at a chunk boundary.
      final arabic = await turn(source, events, 'مرحبا، ما هي خدماتكم؟');
      final arabicText = finalTextOf(arabic);
      print('   text: $arabicText');
      final arabicIntact = RegExp('[؀-ۿ]').hasMatch(arabicText);
      print(
        '   ARABIC: '
        '${arabicIntact ? "script intact" : "NOT intact — check the decoder"}',
      );

      // 4. Structured UI, if the agent has started sending any.
      final allEvents = [...first, ...second, ...arabic];
      final uiEvents = allEvents.whereType<AiChatUiEvent>().toList();
      if (uiEvents.isEmpty) {
        print(
          '\nSTRUCTURED UI: none. The endpoint emitted no `ui` event across '
          '${allEvents.length} events — the known backend gap.',
        );
      } else {
        final validator = AiChatConfig.validator(keepUnsupportedNodes: true);
        for (final ui in uiEvents) {
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
      }

      // 5. Cancellation: dispose must abort, not hang.
      await source.dispose();
      print('\ndisposed cleanly');
    },
    timeout: const Timeout(Duration(minutes: 8)),
  );
}
