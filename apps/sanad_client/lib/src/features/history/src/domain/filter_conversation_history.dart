import 'package:sanad_client/src/features/history/src/domain/conversation_history_entry.dart';

/// Narrows [entries] to those matching [query] — case-insensitive, matching
/// either the title or the preview text.
///
/// Presentation-side and deliberately trivial: the search box filters the
/// list the screen already holds. When the backend gains a history search
/// endpoint this is what it replaces, and because the screen calls exactly
/// this one function, replacing it does not reach the widgets.
///
/// A blank or whitespace-only query is not a filter — it returns [entries]
/// unchanged, so clearing the box restores the full list.
List<ConversationHistoryEntry> filterConversationHistory(
  List<ConversationHistoryEntry> entries,
  String query,
) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return entries;

  return entries
      .where(
        (entry) =>
            entry.title.toLowerCase().contains(needle) ||
            entry.preview.toLowerCase().contains(needle),
      )
      .toList();
}
