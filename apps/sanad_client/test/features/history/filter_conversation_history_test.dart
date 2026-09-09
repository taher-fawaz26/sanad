import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_client/src/features/history/src/domain/conversation_history_entry.dart';
import 'package:sanad_client/src/features/history/src/domain/filter_conversation_history.dart';

/// The search behaviour, as a pure function — the screen only ever calls
/// this, so the edge cases belong here rather than in a widget test that has
/// to type them one character at a time.
void main() {
  ConversationHistoryEntry entry(String id, String title, String preview) =>
      ConversationHistoryEntry(
        id: id,
        title: title,
        preview: preview,
        updatedAt: DateTime(2026, 9, 8, 14, 30),
      );

  final entries = [
    entry('a', 'Emirates ID Renewal', 'Reference number REF-2024-4821.'),
    entry('b', 'Flight Tickets', 'Your flight to Dubai has been booked.'),
    entry('c', 'Home Services', 'Cleaning confirmed for Thursday.'),
  ];

  test('a blank query is not a filter', () {
    expect(filterConversationHistory(entries, ''), entries);
    expect(filterConversationHistory(entries, '   '), entries);
  });

  test('it matches on the title, ignoring case', () {
    expect(
      filterConversationHistory(entries, 'emirates').single.id,
      'a',
    );
    expect(
      filterConversationHistory(entries, 'FLIGHT').single.id,
      'b',
    );
  });

  test('it matches on the preview text too', () {
    // "Dubai" appears in no title — a search that only looked at titles would
    // silently miss the conversation the user remembers by its content.
    expect(filterConversationHistory(entries, 'Dubai').single.id, 'b');
  });

  test('it can match more than one conversation', () {
    // Substring, not word: "e" is in all three titles.
    expect(filterConversationHistory(entries, 'e'), hasLength(3));
  });

  test('a query nothing matches returns empty rather than everything', () {
    expect(filterConversationHistory(entries, 'zzz'), isEmpty);
  });

  test('surrounding whitespace is trimmed off the query', () {
    expect(filterConversationHistory(entries, '  flight  ').single.id, 'b');
  });
}
