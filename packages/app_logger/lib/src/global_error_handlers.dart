import 'dart:async';

import 'package:app_logger/src/error_reporter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Installs global error hooks that route to [ErrorReporter].
///
/// Call inside the [runZonedGuarded] body, after `WidgetsFlutterBinding`
/// initialization. Covers:
/// - `FlutterError.onError` — framework/build/widget errors.
/// - `PlatformDispatcher.instance.onError` — engine-level async errors.
/// - `ErrorWidget.builder` (release only) — a branded fallback instead of the
///   default grey/red error box.
///
/// Uncaught zone errors are routed by the `runZonedGuarded` handler at the
/// call-site; see `runGuarded`.
void installGlobalErrorHandlers() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    ErrorReporter.report(
      details.exception,
      details.stack ?? StackTrace.current,
      fatal: true,
      context: {'source': 'FlutterError', 'library': details.library ?? ''},
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    ErrorReporter.report(
      error,
      stack,
      fatal: true,
      context: const {'source': 'PlatformDispatcher'},
    );
    return true;
  };

  if (kReleaseMode) {
    ErrorWidget.builder = (details) => const _ReleaseErrorFallback();
  }
}

/// Runs [body] inside a guarded zone so uncaught async errors are reported.
///
/// `WidgetsFlutterBinding` must be initialized inside [body] (not before) so
/// the binding is created in the same zone that runs the app.
Future<void> runGuarded(Future<void> Function() body) {
  return runZonedGuarded<Future<void>>(
        body,
        (Object error, StackTrace stack) => ErrorReporter.report(
          error,
          stack,
          fatal: true,
          context: const {'source': 'zone'},
        ),
      ) ??
      Future<void>.value();
}

class _ReleaseErrorFallback extends StatelessWidget {
  const _ReleaseErrorFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFFFFFFF),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Something went wrong.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Color(0xFF333333)),
          ),
        ),
      ),
    );
  }
}
