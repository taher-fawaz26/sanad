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

    test('unknown code maps to error', () async {
      stub(() async => throw PlatformException(code: 'SomethingElse'));
      final r = await provider.authenticate(reason: 'r');
      expect(r.status, BiometricAuthStatus.error);
    });
  });

  group('isSupported', () {
    test('returns device support', () async {
      when(auth.isDeviceSupported).thenAnswer((_) async => true);
      expect(await provider.isSupported(), isTrue);
    });

    test('returns false on PlatformException', () async {
      when(auth.isDeviceSupported).thenThrow(PlatformException(code: 'x'));
      expect(await provider.isSupported(), isFalse);
    });
  });
}
