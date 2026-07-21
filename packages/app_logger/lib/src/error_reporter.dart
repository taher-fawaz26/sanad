import 'package:app_logger/src/app_logger.dart';

/// A sink for errors captured by the global handlers (zone, framework,
/// platform, bloc).
typedef ErrorSink = void Function(
  Object error,
  StackTrace stackTrace, {
  bool fatal,
  Map<String, dynamic>? context,
});

/// Single ownership point for reporting captured errors.
///
/// Defaults to logging via [appLogger] so every captured error is visible
/// immediately. Attach a crash-reporting backend (e.g. Crashlytics via the
/// `analytics` package's `ObservabilityService.logError`) with
/// [ErrorReporter.use] during bootstrap — this keeps the app entry-points and
/// global handlers decoupled from any specific backend. See
/// `docs/ARCHITECTURE_BLUEPRINT.md` §11–§12.
abstract final class ErrorReporter {
  ErrorReporter._();

  static ErrorSink _sink = _defaultSink;

  /// Replace the default logging sink with a crash-reporting backend.
  /// Call once during bootstrap after the backend is initialized.
  static void use(ErrorSink sink) => _sink = sink;

  /// Reset to the default logging sink (primarily for tests).
  static void reset() => _sink = _defaultSink;

  /// Report a captured error to the active sink. Never throws.
  static void report(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
    Map<String, dynamic>? context,
  }) {
    try {
      _sink(error, stackTrace, fatal: fatal, context: context);
    } on Object catch (e, s) {
      // A failing sink must never crash the app.
      appLogger.e('ErrorReporter sink threw', error: e, stackTrace: s);
    }
  }

  static void _defaultSink(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
    Map<String, dynamic>? context,
  }) {
    final label = fatal ? 'FATAL' : 'Non-fatal error';
    final suffix = (context != null && context.isNotEmpty) ? ' $context' : '';
    appLogger.e('$label$suffix', error: error, stackTrace: stackTrace);
  }
}
