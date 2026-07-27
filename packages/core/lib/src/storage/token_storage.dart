/// Abstract persistent token storage.
///
/// Defined in `core` so `network` (which needs to read tokens on every
/// request) and `storage` (which owns the concrete secure implementation)
/// both depend on `core`, not on each other.
abstract class TokenStorage {
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> clearToken();
  Future<void> saveRefreshToken(String token);
  Future<String?> getRefreshToken();
}
