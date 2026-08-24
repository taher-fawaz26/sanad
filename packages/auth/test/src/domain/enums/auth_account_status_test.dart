import 'package:auth/src/domain/enums/auth_account_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthAccountStatus.fromString', () {
    test('parses ACTIVE', () {
      expect(AuthAccountStatus.fromString('ACTIVE'), AuthAccountStatus.active);
    });

    test('parses SUSPENDED', () {
      expect(
        AuthAccountStatus.fromString('SUSPENDED'),
        AuthAccountStatus.suspended,
      );
    });

    test('parses INCOMPLETE', () {
      expect(
        AuthAccountStatus.fromString('INCOMPLETE'),
        AuthAccountStatus.incomplete,
      );
    });

    // Regression: this value used to throw a FormatException, crashing
    // login-verify for any account whose deletion had moved past the grace
    // period into actual execution.
    test('parses SCHEDULED_FOR_DELETION without throwing', () {
      expect(
        AuthAccountStatus.fromString('SCHEDULED_FOR_DELETION'),
        AuthAccountStatus.scheduledForDeletion,
      );
    });

    test('is case-insensitive and trims whitespace', () {
      expect(
        AuthAccountStatus.fromString(' scheduled_for_deletion '),
        AuthAccountStatus.scheduledForDeletion,
      );
    });

    test('throws FormatException for an unrecognized value', () {
      expect(
        () => AuthAccountStatus.fromString('SOMETHING_NEW'),
        throwsFormatException,
      );
    });
  });
}
