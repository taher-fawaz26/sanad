import 'package:equatable/equatable.dart';

/// One past conversation, as the Conversation History screen needs to draw it
/// — Figma's history card (`8102:35064`).
///
/// Deliberately the *card's* shape and nothing more: an id, a title, a
/// one-line preview and when it last moved. The real backend will carry far
/// more per conversation (turns, attachments, resolved actions), and none of
/// that belongs here — the list renders a summary, and widening this entity to
/// the full conversation would push the whole message model into a screen that
/// never opens one.
class ConversationHistoryEntry extends Equatable {
  /// Creates an entry.
  const ConversationHistoryEntry({
    required this.id,
    required this.title,
    required this.preview,
    required this.updatedAt,
  });

  /// Stable identity — the list's key, and what a tap will eventually carry
  /// to whatever route opens a stored conversation.
  final String id;

  /// The conversation's subject, shown on the card's header row.
  final String title;

  /// The last message's text, shown beneath the header row.
  final String preview;

  /// When the conversation last changed; rendered as the card's timestamp.
  final DateTime updatedAt;

  /// Returns a copy with the given fields replaced.
  ///
  /// [id] is deliberately not replaceable: it is the list's key and the
  /// identity a rename must preserve — a renamed conversation is the same
  /// conversation.
  ConversationHistoryEntry copyWith({
    String? title,
    String? preview,
    DateTime? updatedAt,
  }) => ConversationHistoryEntry(
    id: id,
    title: title ?? this.title,
    preview: preview ?? this.preview,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  List<Object?> get props => [id, title, preview, updatedAt];
}
