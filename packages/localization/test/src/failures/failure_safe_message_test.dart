import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localization/localization.dart';

void main() {
  // No EasyLocalization ancestor in this sandbox, so `.tr()` returns the raw
  // key — which is exactly what we want to assert against.
  group('localizedSafeMessage', () {
    test('replaces a request-shape complaint with the generic 400 key', () {
      // SAN-774: this exact string was shown to users in a snackbar.
      const failure = ValidationFailure(
        message: 'property cityId should not exist',
      );

      expect(failure.localizedSafeMessage(), 'errors.bad_request');
      expect(
        failure.localizedMessage(),
        'property cityId should not exist',
        reason: 'localizedMessage still passes prose through verbatim',
      );
    });

    test('replaces enum/field-shape complaints too', () {
      for (final message in [
        'day must be one of the following values: Monday,Tuesday',
        'property lang should not exist',
        'availability must be an array',
      ]) {
        expect(
          ValidationFailure(message: message).localizedSafeMessage(),
          'errors.bad_request',
          reason: message,
        );
      }
    });

    test('keeps genuinely user-facing validation prose', () {
      for (final message in [
        'Phone must be a valid UAE number',
        'This email is already registered',
      ]) {
        expect(
          ValidationFailure(message: message).localizedSafeMessage(),
          message,
          reason: message,
        );
      }
    });

    test('non-validation failures are untouched', () {
      // A business rule mentioning a field name must not be swallowed.
      const businessRule = BusinessRuleFailure(
        message: 'Cannot delete the only branch',
      );
      expect(
        businessRule.localizedSafeMessage(),
        'Cannot delete the only branch',
      );
    });

    test('an i18n key still resolves as a key', () {
      const failure = NoInternetFailure(message: 'errors.no_internet');
      expect(failure.localizedSafeMessage(), 'errors.no_internet');
    });
  });
}
