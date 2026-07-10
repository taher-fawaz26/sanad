/// Abstract persistent token storage — implemented in sand_storage.
abstract class TokenStorage {
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> clearToken();
  Future<void> saveRefreshToken(String token);
  Future<String?> getRefreshToken();
}
