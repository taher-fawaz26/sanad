import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Failure.backendCode', () {
    test('reads a top-level code', () {
      const failure = ConflictFailure(
        message: 'Closed then',
        code: '409',
        metadata: {'code': 'OUTSIDE_HOURS'},
      );
      expect(failure.backendCode, 'OUTSIDE_HOURS');
    });

    test('does not disturb Failure.code, which carries the HTTP status', () {
      // isRetryable parses `code` as an int; promoting a business code into it
      // would silently break that.
      const failure = ConflictFailure(
        message: 'x',
        code: '409',
        metadata: {'code': 'NO_COVERAGE'},
      );
      expect(failure.code, '409');
      expect(failure.isRetryable, isFalse);
    });

    test('reads the errorCode and error_code aliases', () {
      expect(
        const ServerFailure(
          message: 'x',
          code: '403',
          metadata: {'errorCode': 'ACCOUNT_UNVERIFIED'},
        ).backendCode,
        'ACCOUNT_UNVERIFIED',
      );
      expect(
        const ServerFailure(
          message: 'x',
          code: '403',
          metadata: {'error_code': 'account_unverified'},
        ).backendCode,
        'ACCOUNT_UNVERIFIED',
      );
    });

    test('ignores a NestJS reason phrase in `error`', () {
      expect(
        const ConflictFailure(
          message: 'x',
          code: '409',
          metadata: {'error': 'Conflict'},
        ).backendCode,
        isNull,
      );
    });

    test('returns null with no metadata or a blank value', () {
      expect(
        const ConflictFailure(message: 'x', code: '409').backendCode,
        isNull,
      );
      expect(
        const ConflictFailure(
          message: 'x',
          code: '409',
          metadata: {'code': '  '},
        ).backendCode,
        isNull,
      );
      expect(
        const ConflictFailure(
          message: 'x',
          code: '409',
          metadata: {'code': 7},
        ).backendCode,
        isNull,
      );
    });
  });
}
