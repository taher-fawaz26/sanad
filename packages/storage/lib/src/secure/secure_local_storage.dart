import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:storage/src/hive/local_storage.dart';

/// Keychain/Keystore-backed [LocalStorage].
class SecureLocalStorage implements LocalStorage {
  const SecureLocalStorage(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> load({required String key, String? boxName}) =>
      _storage.read(key: key);

  @override
  Future<void> save({
    required String key,
    required Object? value,
    String? boxName,
  }) {
    if (value == null) return _storage.delete(key: key);
    return _storage.write(key: key, value: value.toString());
  }

  @override
  Future<void> delete({required String key, String? boxName}) =>
      _storage.delete(key: key);
}
