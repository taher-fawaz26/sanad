part of 'chat_context_cubit.dart';

/// What contextual information the conversation currently has, if any.
final class ChatContextState extends Equatable {
  /// Creates a contextual state. The default — no content — is what every
  /// conversation starts in and returns to.
  const ChatContextState({this.content});

  /// The payload on offer, or null when there is nothing.
  final ChatContextContent? content;

  /// Whether the contextual sheet should exist at all.
  ///
  /// The single answer to "is there a sheet?", read by the sheet and by
  /// nothing else. When this is false the surface is not merely collapsed —
  /// it is absent: no panel, no drag handle, no strip of white behind the
  /// composer.
  bool get isAvailable => content != null;

  @override
  List<Object?> get props => [content];
}
