import 'dart:async';

import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/ai_contextual_event_source.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/entities/chat_context_content.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/chat_context_cubit.dart';
import 'package:testing/testing.dart';

/// The one thing that decides whether the contextual layer exists.
///
/// Kept deliberately small: this cubit holds no presentation state at all —
/// how far open the layer is, whether a drag is in flight and which snap it
/// settled on all belong to `AiChatContextLayer`, and a test that could observe
/// them here would mean the split had been broken.
///
/// The group at the bottom covers the half that matters most for the mock
/// journey: the content arrives **from the transport**, so nothing in the
/// presentation layer can invent it.
void main() {
  ChatContextContent content(String id) => ChatContextContent(
    id: id,
    peekLabel: 'You have 8 new offers',
    document: AiUiDocument(
      schemaVersion: AiUiDocument.currentSchemaVersion,
      blocks: [AiUiTextNode(id: '${id}_t', text: 'Ahmed K')],
    ),
  );

  test('a conversation starts with nothing to offer', () {
    final cubit = ChatContextCubit();
    addTearDown(cubit.close);

    expect(cubit.state.isAvailable, isFalse);
    expect(cubit.state.content, isNull);
  });

  blocTest<ChatContextCubit, ChatContextState>(
    'showing content makes the layer available',
    build: ChatContextCubit.new,
    act: (cubit) => cubit.show(content('a')),
    expect: () => [ChatContextState(content: content('a'))],
    verify: (cubit) => expect(cubit.state.isAvailable, isTrue),
  );

  blocTest<ChatContextCubit, ChatContextState>(
    'showing replaces rather than stacks — there is one contextual surface, '
    'and it is about the most recent thing the agent produced',
    build: ChatContextCubit.new,
    act: (cubit) => cubit
      ..show(content('a'))
      ..show(content('b')),
    expect: () => [
      ChatContextState(content: content('a')),
      ChatContextState(content: content('b')),
    ],
  );

  blocTest<ChatContextCubit, ChatContextState>(
    'clearing takes the layer away',
    build: ChatContextCubit.new,
    seed: () => ChatContextState(content: content('a')),
    act: (cubit) => cubit.clear(),
    expect: () => [const ChatContextState()],
  );

  group('content comes from the transport', () {
    test('a source with no contextual channel leaves it permanently empty', () {
      // Which is exactly right for the live transports: their agent has no
      // side channel yet, so the layer simply never appears.
      final cubit = ChatContextCubit();
      addTearDown(cubit.close);

      expect(cubit.state.isAvailable, isFalse);
    });

    test('payloads published by the source reach the state', () async {
      final controller = StreamController<ChatContextContent?>.broadcast();
      addTearDown(controller.close);
      final cubit = ChatContextCubit(source: _StubSource(controller.stream));
      addTearDown(cubit.close);

      controller.add(content('a'));
      await pumpEventQueue();
      expect(cubit.state.content, content('a'));

      // Null is the agent withdrawing what it offered, not an empty payload.
      controller.add(null);
      await pumpEventQueue();
      expect(cubit.state.isAvailable, isFalse);
    });

    test('closing the cubit stops following the source', () async {
      final controller = StreamController<ChatContextContent?>.broadcast();
      addTearDown(controller.close);
      final cubit = ChatContextCubit(source: _StubSource(controller.stream));

      await cubit.close();
      controller.add(content('a'));
      await pumpEventQueue();

      // No emit-after-close, which would throw rather than merely be wasteful.
      expect(cubit.state.isAvailable, isFalse);
    });
  });
}

/// A transport that publishes contextual content and nothing else.
class _StubSource implements AiContextualEventSource {
  const _StubSource(this.contextualContent);

  @override
  final Stream<ChatContextContent?> contextualContent;
}
