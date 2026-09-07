import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/ai_chat_message.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/ai_chat_bloc.dart';

/// The landing-vs-conversation rule the Home screen's whole composition
/// hangs off: the hero and the starter suggestions are shown when — and only
/// when — [AiChatState.showsLanding] is true, and the message list is shown
/// exactly when it is false.
///
/// Pinned here rather than only in a widget test because three widgets read
/// this one getter; if it drifts they all drift together, and the failure
/// mode (a hero left floating behind a live conversation) is precisely what
/// the design forbids.
void main() {
  AiChatMessage userMessage(String text) =>
      AiChatMessage.user(id: 'm1', text: text);

  group('AiChatState.showsLanding', () {
    test('an untouched conversation is the landing composition', () {
      const state = AiChatState();

      expect(state.isEmpty, isTrue);
      expect(state.showsLanding, isTrue);
    });

    test('the first sent message ends it', () {
      final state = AiChatState(messages: [userMessage('hello')]);

      expect(state.showsLanding, isFalse);
    });

    test(
      'the agent signalling a reply ends it too, before any message exists — '
      'otherwise the hero would flash back in while the answer streams',
      () {
        const state = AiChatState(isTyping: true);

        // Still empty by the list's own measure...
        expect(state.isEmpty, isTrue);
        // ...but the turn has begun, so the landing composition is over.
        expect(state.showsLanding, isFalse);
      },
    );

    test('it stays false once a conversation has messages and typing ends', () {
      final state = AiChatState(
        messages: [userMessage('hello')],
      );

      expect(state.isTyping, isFalse);
      expect(state.showsLanding, isFalse);
    });

    test(
      'clearing the conversation returns to the landing composition, so a '
      'fresh chat gets its hero back',
      () {
        final started = AiChatState(messages: [userMessage('hello')]);
        final cleared = started.copyWith(messages: const []);

        expect(started.showsLanding, isFalse);
        expect(cleared.showsLanding, isTrue);
      },
    );

    test(
      'it is not a function of composer focus or draft text — the state '
      'carries neither, so focusing the field cannot hide the hero (the '
      'regression this getter exists to prevent)',
      () {
        const state = AiChatState();

        // The only inputs are the conversation's own facts.
        expect(state.showsLanding, state.isEmpty && !state.isTyping);
      },
    );
  });
}
