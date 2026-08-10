import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localization/localization.dart';

void main() {
  group('FailureLocalizer.errorKey — type-based mapping', () {
    test('maps each failure type to its canonical key', () {
      expect(
        const NoInternetFailure(message: 'x').errorKey,
        'errors.no_internet',
      );
      expect(const TimeoutFailure(message: 'x').errorKey, 'errors.timeout');
      expect(
        const SecureConnectionFailure(message: 'x').errorKey,
        'errors.secure_connection_failed',
      );
      expect(
        const UnauthorizedFailure(message: 'x').errorKey,
        'errors.unauthorized',
      );
      expect(
        const UnauthorizedRoleFailure(message: 'x').errorKey,
        'errors.unauthorized',
      );
      expect(
        const ValidationFailure(message: 'x').errorKey,
        'errors.bad_request',
      );
      expect(const CacheFailure(message: 'x').errorKey, 'errors.cache_error');
      expect(const ServerFailure(message: 'x').errorKey, 'errors.server_error');
      expect(const UnknownFailure(message: 'x').errorKey, 'errors.unknown');
    });
  });

  group('FailureLocalizer.localizedMessage — backend prose passthrough', () {
    test('returns multi-word server prose verbatim', () {
      expect(
        const ServerFailure(
          message: 'Cannot delete the only branch',
        ).localizedMessage(),
        'Cannot delete the only branch',
      );
    });

    test(
      'returns SINGLE-word prose verbatim (contains-space regression fix)',
      () {
        // The old `message.contains(' ')` heuristic would have treated
        // "Forbidden" as an i18n key and shown a broken literal. It must not.
        expect(
          const UnauthorizedRoleFailure(
            message: 'Forbidden',
          ).localizedMessage(),
          'Forbidden',
        );
      },
    );
  });

  group('ValidationFailureLocalizer.localizedMessages', () {
    test('returns every backend validation message', () {
      const failure = ValidationFailure(
        message: 'Email is required',
        messages: ['Email is required', 'Password is too short'],
      );
      expect(failure.localizedMessages(), <String>[
        'Email is required',
        'Password is too short',
      ]);
    });

    test('falls back to the single resolved message when list is empty', () {
      const failure = ValidationFailure(message: 'Invalid input');
      expect(failure.localizedMessages(), <String>['Invalid input']);
    });
  });
}
