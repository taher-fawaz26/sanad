import 'package:account_settings/src/data/repositories/app_lock_repository_impl.dart';
import 'package:account_settings/src/domain/enums/app_lock_capability.dart';
import 'package:core/core.dart';
import 'package:device/device.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:storage/storage.dart';

class _MockBiometricService extends Mock implements BiometricService {}

/// In-memory stand-in for the Keychain/Keystore store, so a "restart" is just
/// a new repository over the same map.
class _FakeSecureStorage implements LocalStorage {
  final Map<String, Object?> values = {};

  @override
  Future<Object?> load({required String key, String? boxName}) async =>
      values[key];

  @override
  Future<void> save({
    required String key,
    required Object? value,
    String? boxName,
  }) async {
    if (value == null) {
      values.remove(key);
      return;
    }
    values[key] = value;
  }

  @override
  Future<void> delete({required String key, String? boxName}) async =>
      values.remove(key);
}

void main() {
  late _FakeSecureStorage storage;
  late _MockBiometricService biometrics;

  AppLockRepositoryImpl build() => AppLockRepositoryImpl(
    secureStorage: storage,
    biometrics: biometrics,
  );

  setUp(() {
    storage = _FakeSecureStorage();
    biometrics = _MockBiometricService();
    when(biometrics.isSupported).thenAnswer((_) async => true);
  });

  group('enabled preference', () {
    test('defaults to false when nothing is stored', () async {
      expect(await build().isEnabled(), isFalse);
    });

    test('round-trips true', () async {
      final repo = build();
      await repo.setEnabled(enabled: true);
      expect(await repo.isEnabled(), isTrue);
    });

    test(
      'survives a restart (a fresh repository over the same store)',
      () async {
        await build().setEnabled(enabled: true);
        expect(await build().isEnabled(), isTrue);
      },
    );

    test(
      'is written to secure storage, not the plaintext default box',
      () async {
        await build().setEnabled(enabled: true);
        expect(
          storage.values,
          containsPair(StorageKeys.appLockEnabled, 'true'),
        );
      },
    );

    test('setEnabled(false) round-trips', () async {
      final repo = build();
      await repo.setEnabled(enabled: true);
      await repo.setEnabled(enabled: false);
      expect(await repo.isEnabled(), isFalse);
    });
  });

  group('offer flag', () {
    test('defaults to false and latches once marked', () async {
      final repo = build();
      expect(await repo.hasBeenOffered(), isFalse);
      await repo.markOffered();
      expect(await repo.hasBeenOffered(), isTrue);
    });
  });

  group('clear', () {
    test('removes both preferences', () async {
      final repo = build();
      await repo.setEnabled(enabled: true);
      await repo.markOffered();

      await repo.clear();

      expect(await repo.isEnabled(), isFalse);
      expect(await repo.hasBeenOffered(), isFalse);
      expect(storage.values, isEmpty);
    });
  });

  group('capability', () {
    test('supported device is available', () async {
      expect(await build().capability(), AppLockCapability.available);
    });

    test('unsupported device is unsupported', () async {
      when(biometrics.isSupported).thenAnswer((_) async => false);
      expect(await build().capability(), AppLockCapability.unsupported);
    });

    test('is memoised — repeated calls hit the platform once', () async {
      final repo = build();
      await repo.capability();
      await repo.capability();
      await repo.capability();
      verify(biometrics.isSupported).called(1);
    });

    test('concurrent callers share one probe', () async {
      final repo = build();
      await Future.wait([repo.capability(), repo.capability()]);
      verify(biometrics.isSupported).called(1);
    });
  });
}
