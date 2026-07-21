import 'package:app_logger/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(ErrorReporter.reset);

  group('ErrorReporter', () {
    test('routes reports to the attached sink with fatal + context', () {
      Object? capturedError;
      bool? capturedFatal;
      Map<String, dynamic>? capturedContext;

      ErrorReporter.use((error, stack, {bool fatal = false, context}) {
        capturedError = error;
        capturedFatal = fatal;
        capturedContext = context;
      });

      final error = StateError('boom');
      ErrorReporter.report(
        error,
        StackTrace.current,
        fatal: true,
        context: const {'source': 'test'},
      );

      expect(capturedError, same(error));
      expect(capturedFatal, isTrue);
      expect(capturedContext, const {'source': 'test'});
    });

    test('a throwing sink never propagates out of report()', () {
      ErrorReporter.use((error, stack, {bool fatal = false, context}) {
        throw StateError('sink failed');
      });

      expect(
        () => ErrorReporter.report(Exception('x'), StackTrace.current),
        returnsNormally,
      );
    });

    test('reset restores the default sink (no attached sink throws)', () {
      ErrorReporter.use((error, stack, {bool fatal = false, context}) {
        throw StateError('should be reset away');
      });
      ErrorReporter.reset();

      expect(
        () => ErrorReporter.report(Exception('x'), StackTrace.current),
        returnsNormally,
      );
    });
  });
}
