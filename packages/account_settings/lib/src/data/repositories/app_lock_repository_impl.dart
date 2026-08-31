import 'package:account_settings/src/domain/enums/app_lock_capability.dart';
import 'package:account_settings/src/domain/repositories/app_lock_repository.dart';
import 'package:core/core.dart';
import 'package:device/device.dart';
import 'package:storage/storage.dart';

/// [AppLockRepository] backed by Keychain/Keystore storage and the `device`
/// package's biometric capability probe.
class AppLockRepositoryImpl implements AppLockRepository {
  AppLockRepositoryImpl({
    required LocalStorage secureStorage,
    required BiometricService biometrics,
  }) : _storage = secureStorage,
       _biometrics = biometrics;

  final LocalStorage _storage;
  final BiometricService _biometrics;

  /// In-flight/finished capability probe, computed at most once per process.
  ///
  /// Holding the *future* rather than the value means concurrent callers (the
  /// gate at startup and the Security page) share a single platform channel
  /// round-trip instead of racing two.
  Future<AppLockCapability>? _capability;

  @override
  Future<bool> isEnabled() async =>
      await _storage.load(key: StorageKeys.appLockEnabled) == 'true';

  @override
  Future<void> setEnabled({required bool enabled}) => _storage.save(
    key: StorageKeys.appLockEnabled,
    value: enabled.toString(),
  );

  @override
  Future<bool> hasBeenOffered() async =>
      await _storage.load(key: StorageKeys.appLockOffered) == 'true';

  @override
  Future<void> markOffered() => _storage.save(
    key: StorageKeys.appLockOffered,
    value: 'true',
  );

  @override
  Future<void> clear() async {
    await _storage.delete(key: StorageKeys.appLockEnabled);
    await _storage.delete(key: StorageKeys.appLockOffered);
  }

  @override
  Future<AppLockCapability> capability() => _capability ??= _probeCapability();

  Future<AppLockCapability> _probeCapability() async {
    final supported = await _biometrics.isSupported();
    return supported
        ? AppLockCapability.available
        : AppLockCapability.unsupported;
  }
}
