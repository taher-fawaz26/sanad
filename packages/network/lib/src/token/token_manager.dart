/// Contract for managing authentication tokens in memory
/// and persistent storage.
abstract class TokenManager {
  String? get accessToken;
  String? get refreshToken;

  Future<void> init();

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });

  Future<void> clearTokens();

  /// Exchanges the stored refresh token for a new pair.
  /// Throws [TokenRefreshException] on failure.
  Future<String> refreshAccessToken();
}

class TokenRefreshException implements Exception {
  const TokenRefreshException(this.message);

  final String message;

  @override
  String toString() => 'TokenRefreshException: $message';
}
