import 'package:core/core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Concrete [TokenStorage] backed by [FlutterSecureStorage].
class TokenStorageImpl implements TokenStorage {
  const TokenStorageImpl(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<void> saveToken(String token) =>
      _storage.write(key: StorageKeys.authToken, value: token);

  @override
  Future<String?> getToken() => _storage.read(key: StorageKeys.authToken);

  @override
  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: StorageKeys.refreshToken, value: token);

  @override
  Future<String?> getRefreshToken() =>
      _storage.read(key: StorageKeys.refreshToken);

  @override
  Future<void> clearToken() async {
    await _storage.delete(key: StorageKeys.authToken);
    await _storage.delete(key: StorageKeys.refreshToken);
  }
}
