import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// App-wide logger. Use `appLogger.d`, `appLogger.i`, `appLogger.w`,
/// `appLogger.e`.
final Logger appLogger = Logger(
  filter: _AppLogFilter(),
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 100,
  ),
);

class _AppLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    if (kReleaseMode) return event.level.index >= Level.warning.index;
    return true;
  }
}
