import 'package:sanad_client/src/features/history/src/domain/conversation_history_entry.dart';

/// Where the Conversation History screen gets its entries.
///
/// The whole point of this one-method seam: the screen depends on it and not
/// on the mock behind it, so swapping in a repository backed by the real
/// history endpoint is a change to *what is registered*, not to any widget.
///
/// Synchronous on purpose. There is no history API yet, and giving this a
/// `Future`/`TaskEither` today would mean inventing loading and failure states
/// the screen has no design for — the real repository can add them, along with
/// the states Figma will specify for them, when there is something to load.
// ignore: one_member_abstracts
abstract interface class ConversationHistorySource {
  /// Returns the conversations to list, newest activity first.
  List<ConversationHistoryEntry> load();
}
