import 'package:ai_ui_protocol/src/diagnostics/ai_ui_diagnostic.dart';
import 'package:ai_ui_protocol/src/domain/ai_ui_document.dart';
import 'package:equatable/equatable.dart';

/// What came back from parsing an AI payload.
///
/// A result is never an exception and never a bare `null`: either there is a
/// renderable [document], or there is not, and either way [diagnostics]
/// explains what the client decided to ignore. Callers are expected to fall
/// back to the message's plain text when [hasRenderableUi] is false.
final class AiUiParseResult extends Equatable {
  const AiUiParseResult({this.document, this.diagnostics = const []});

  const AiUiParseResult.rejected(List<AiUiDiagnostic> diagnostics)
    : this(diagnostics: diagnostics);

  final AiUiDocument? document;
  final List<AiUiDiagnostic> diagnostics;

  /// True only when there is a document *and* it has at least one block worth
  /// drawing. A payload whose every node was dropped is not renderable.
  bool get hasRenderableUi => document?.isNotEmpty ?? false;

  bool get hasDiagnostics => diagnostics.isNotEmpty;

  @override
  List<Object?> get props => [document, diagnostics];
}
