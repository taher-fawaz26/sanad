import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:app_logger/app_logger.dart';

/// Where the client reports what it refused to render.
///
/// Diagnostics are deliberately shape-only — a code, a document path, a node
/// type. They never carry the AI's or the user's prose (the protocol package
/// enforces that at construction), so a sink can log freely without leaking
/// conversation content into crash reports.
abstract class AiUiDiagnosticsSink {
  const AiUiDiagnosticsSink();

  void report(AiUiDiagnostic diagnostic);

  void reportAll(Iterable<AiUiDiagnostic> diagnostics) {
    for (final diagnostic in diagnostics) {
      report(diagnostic);
    }
  }
}

/// Drops everything. The right default for a widget test that does not care.
final class NoopAiUiDiagnosticsSink extends AiUiDiagnosticsSink {
  const NoopAiUiDiagnosticsSink();

  @override
  void report(AiUiDiagnostic diagnostic) {}
}

/// Routes diagnostics to `appLogger`, and renderer failures additionally to
/// [ErrorReporter] as non-fatal.
///
/// [ErrorReporter] is the seam an app swaps for a crash backend at bootstrap
/// (`ErrorReporter.use(...)`), so wiring a real destination later needs no
/// change here. Note that `appLogger` filters below `warning` in release, so
/// today the informational codes are debug-only — that is a deliberate
/// prototype limitation, not an oversight.
final class LoggingAiUiDiagnosticsSink extends AiUiDiagnosticsSink {
  const LoggingAiUiDiagnosticsSink();

  @override
  void report(AiUiDiagnostic diagnostic) {
    if (diagnostic.code == AiUiDiagnosticCode.rendererFailure) {
      ErrorReporter.report(
        StateError('ai_ui renderer failure'),
        StackTrace.current,
        context: <String, dynamic>{
          'code': diagnostic.code.wire,
          'path': diagnostic.path,
          'nodeType': diagnostic.nodeType,
          'detail': diagnostic.detail,
        },
      );
      return;
    }
    appLogger.w('[ai_ui] $diagnostic');
  }
}

/// Keeps everything in memory so a test can assert on what was rejected.
final class RecordingAiUiDiagnosticsSink extends AiUiDiagnosticsSink {
  RecordingAiUiDiagnosticsSink();

  final List<AiUiDiagnostic> diagnostics = [];

  Iterable<AiUiDiagnosticCode> get codes => diagnostics.map((d) => d.code);

  bool hasCode(AiUiDiagnosticCode code) =>
      diagnostics.any((d) => d.code == code);

  void clear() => diagnostics.clear();

  @override
  void report(AiUiDiagnostic diagnostic) => diagnostics.add(diagnostic);
}
