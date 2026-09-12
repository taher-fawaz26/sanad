import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:equatable/equatable.dart';

/// The contextual information the conversation currently has to offer.
///
/// The sheet knows nothing about offers: it renders the [document] it is
/// handed and shows [peekLabel] on its affordance. That is the whole contract,
/// and it is deliberately the smallest one that still lets a second kind of
/// context arrive later without touching the sheet.
///
/// [document] is an already-validated AI UI document, so the contextual
/// surface renders through exactly the same components as a chat bubble.
final class ChatContextContent extends Equatable {
  /// Creates a contextual payload.
  const ChatContextContent({
    required this.id,
    required this.peekLabel,
    required this.document,
  });

  /// Identifies this payload; replacing the content with a different [id] is
  /// what tells the sheet its body changed.
  final String id;

  /// The summary on the affordance — "You have 8 new offers". Agent-supplied
  /// prose, rendered verbatim; the client adds its own localized call to
  /// action beside it.
  final String peekLabel;

  /// What the sheet renders once opened.
  final AiUiDocument document;

  @override
  List<Object?> get props => [id, peekLabel, document];
}
