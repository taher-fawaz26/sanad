import 'package:core/core.dart';
import 'package:test/test.dart';

void main() {
  group('FailureKindX.isRetryable', () {
    test('transient transport failures are retryable', () {
      expect(const NoInternetFailure(message: 'x').isRetryable, isTrue);
      expect(const TimeoutFailure(message: 'x').isRetryable, isTrue);
    });

    test('validation / auth / permission / secure are NOT retryable', () {
      expect(const ValidationFailure(message: 'x').isRetryable, isFalse);
      expect(const UnauthorizedFailure(message: 'x').isRetryable, isFalse);
      expect(const UnverifiedUserFailure(message: 'x').isRetryable, isFalse);
      expect(const UnauthorizedRoleFailure(message: 'x').isRetryable, isFalse);
      expect(const SecureConnectionFailure(message: 'x').isRetryable, isFalse);
    });

    test('server 5xx is retryable, 4xx is not', () {
      expect(
        const ServerFailure(message: 'x', code: '500').isRetryable,
        isTrue,
      );
      expect(
        const ServerFailure(message: 'x', code: '503').isRetryable,
        isTrue,
      );
      expect(
        const ServerFailure(message: 'x', code: '404').isRetryable,
        isFalse,
      );
      expect(
        const ServerFailure(message: 'x', code: '400').isRetryable,
        isFalse,
      );
    });

    test('server failure with no/unparseable code is treated as transient', () {
      expect(const ServerFailure(message: 'x').isRetryable, isTrue);
    });

    test('cache / location / unknown are retryable', () {
      expect(const CacheFailure(message: 'x').isRetryable, isTrue);
      expect(const LocationFailure(message: 'x').isRetryable, isTrue);
      expect(const UnknownFailure(message: 'x').isRetryable, isTrue);
    });

    test('cancelled request (NetworkFailure) is NOT retryable', () {
      expect(const NetworkFailure(message: 'x').isRetryable, isFalse);
    });

    test('rate limit is retryable; conflict and business-rule are not', () {
      expect(const RateLimitFailure(message: 'x').isRetryable, isTrue);
      expect(const ConflictFailure(message: 'x').isRetryable, isFalse);
      expect(const BusinessRuleFailure(message: 'x').isRetryable, isFalse);
    });
  });
}
