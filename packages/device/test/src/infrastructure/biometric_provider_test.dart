import 'package:device/src/domain/enums/biometric_auth_status.dart';
import 'package:device/src/domain/enums/biometric_type.dart' as domain;
import 'package:device/src/infrastructure/providers/biometric_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth/local_auth.dart';
import 'package:mocktail/mocktail.dart';

class _MockLocalAuth extends Mock implements LocalAuthentication {}

void main() {
  late _MockLocalAuth auth;
  late BiometricProvider provider;

  setUpAll(() {
    registerFallbackValue(const AuthenticationOptions());
  });

  setUp(() {
    auth = _MockLocalAuth();
    provider = BiometricProvider(auth);
  });

  group('availableBiometrics mapping', () {
    test('maps local_auth types to domain types', () async {
      when(auth.getAvailableBiometrics).thenAnswer(
        (_) async => [
          BiometricType.face,
          BiometricType.fingerprint,
          BiometricType.iris,
          BiometricType.strong,
          BiometricType.weak,
        ],
      );

      expect(await provider.availableBiometrics(), [
        domain.BiometricType.face,
        domain.BiometricType.fingerprint,
        domain.BiometricType.iris,
        domain.BiometricType.strong,
        domain.BiometricType.weak,
      ]);
    });

    test('returns empty list on PlatformException', () async {
      when(auth.getAvailableBiometrics).thenThrow(PlatformException(code: 'x'));
      expect(await provider.availableBiometrics(), isEmpty);
    });
  });

  group('authenticate result mapping', () {
    void stub(Future<bool> Function() answer) {
      when(
        () => auth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) => answer());
    }

    test('true → success', () async {
      stub(() async => true);
      final r = await provider.authenticate(reason: 'r');
      expect(r.status, BiometricAuthStatus.success);
      expect(r.isSuccess, isTrue);
    });

    test('false → failed', () async {
      stub(() async => false);
      final r = await provider.authenticate(reason: 'r');
      expect(r.status, BiometricAuthStatus.failed);
    });

    test('notAvailable code maps to notAvailable', () async {
      stub(() async => throw PlatformException(code: auth_error.notAvailable));
      final r = await provider.authenticate(reason: 'r');
      expect(r.status, BiometricAuthStatus.notAvailable);
    });

    test('notEnrolled code maps to notEnrolled', () async {
      stub(() async => throw PlatformException(code: auth_error.notEnrolled));
      final r = await provider.authenticate(reason: 'r');
      expect(r.status, BiometricAuthStatus.notEnrolled);
    });

    test('lockedOut code maps to lockedOut', () async {
      stub(() async => throw PlatformException(code: auth_error.lockedOut));
      final r = await provider.authenticate(reason: 'r');
      expect(r.status, BiometricAuthStatus.lockedOut);
    });

    test('permanentlyLockedOut maps to lockedOut', () async {
      stub(
        () async =>
            throw PlatformException(code: auth_error.permanentlyLockedOut),
      );
      final r = await provider.authenticate(reason: 'r');
      expect(r.status, BiometricAuthStatus.lockedOut);
    });

    test('passcodeNotSet maps to passcodeNotSet', () async {
      stub(
        () async => throw PlatformException(code: auth_error.passcodeNotSet),
      );
      final r = await provider.authenticate(reason: 'r');
      expect(r.status, BiometricAuthStatus.passcodeNotSet);
    });

    test('otherOperatingSystem maps to notAvailable', () async {
      stub(
        () async =>
            throw PlatformException(code: auth_error.otherOperatingSystem),
      );
      final r = await provider.authenticate(reason: 'r');
      expect(r.status, BiometricAuthStatus.notAvailable);
    });

    test('biometricOnlyNotSupported maps to error', () async {
      stub(
        () async => throw PlatformException(
          code: auth_error.biometricOnlyNotSupported,
        ),
      );
      final r = await provider.authenticate(reason: 'r');
      expect(r.status, BiometricAuthStatus.error);
    });

    test('unknown code maps to error', () async {
      stub(() async => throw PlatformException(code: 'SomethingElse'));
      final r = await provider.authenticate(reason: 'r');
      expect(r.status, BiometricAuthStatus.error);
    });

    test('carries the platform message as diagnostic detail', () async {
      stub(
        () async => throw PlatformException(
          code: auth_error.lockedOut,
          message: 'Too many attempts',
        ),
      );
      final r = await provider.authenticate(reason: 'r');
      expect(r.message, 'Too many attempts');
    });

    test(
      'passes the caller reason and biometricOnly through to the plugin',
      () async {
        stub(() async => true);
        await provider.authenticate(
          reason: 'unlock sanad',
          biometricOnly: true,
        );

        final captured = verify(
          () => auth.authenticate(
            localizedReason: captureAny(named: 'localizedReason'),
            options: captureAny(named: 'options'),
          ),
        ).captured;

        expect(captured[0], 'unlock sanad');
        final options = captured[1] as AuthenticationOptions;
        expect(options.biometricOnly, isTrue);
        // stickyAuth keeps the OS prompt alive across a backgrounding instead
        // of silently failing when the app returns to the foreground.
        expect(options.stickyAuth, isTrue);
      },
    );

    // Regression guard for a documented plugin limitation: `local_auth`
    // defines no cancellation code, so nothing the plugin can emit may be
    // mapped onto `BiometricAuthStatus.cancelled`. Any UI that branches on
    // `cancelled` would be dead code. See BiometricProvider._mapError.
    test('never produces cancelled for any plugin outcome', () async {
      const codes = [
        auth_error.notAvailable,
        auth_error.notEnrolled,
        auth_error.passcodeNotSet,
        auth_error.lockedOut,
        auth_error.permanentlyLockedOut,
        auth_error.otherOperatingSystem,
        auth_error.biometricOnlyNotSupported,
        'SomethingElse',
      ];
      for (final code in codes) {
        stub(() async => throw PlatformException(code: code));
        final r = await provider.authenticate(reason: 'r');
        expect(
          r.status,
          isNot(BiometricAuthStatus.cancelled),
          reason: 'code "$code" must not map to cancelled',
        );
      }

      for (final answer in [true, false]) {
        stub(() async => answer);
        final r = await provider.authenticate(reason: 'r');
        expect(r.status, isNot(BiometricAuthStatus.cancelled));
      }
    });
  });

  group('isSupported', () {
    test('returns device support', () async {
      when(auth.isDeviceSupported).thenAnswer((_) async => true);
      expect(await provider.isSupported(), isTrue);
    });

    test('returns false when the device is unsupported', () async {
      when(auth.isDeviceSupported).thenAnswer((_) async => false);
      expect(await provider.isSupported(), isFalse);
    });

    test('returns false on PlatformException', () async {
      when(auth.isDeviceSupported).thenThrow(PlatformException(code: 'x'));
      expect(await provider.isSupported(), isFalse);
    });
  });

  group('cancel', () {
    test('delegates to stopAuthentication', () async {
      when(auth.stopAuthentication).thenAnswer((_) async => true);
      await provider.cancel();
      verify(auth.stopAuthentication).called(1);
    });

    test('swallows PlatformException (cancellation is best-effort)', () async {
      when(auth.stopAuthentication).thenThrow(PlatformException(code: 'x'));
      await expectLater(provider.cancel(), completes);
    });
  });
}
