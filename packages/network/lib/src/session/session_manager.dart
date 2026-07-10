import 'package:network/src/token/token_manager.dart';

/// Centralizes session lifecycle. Source of truth for authentication state.
/// Does not depend on presentation layer.
class SessionManager {
  const SessionManager(this._tokenManager);

  final TokenManager _tokenManager;

  bool get isAuthenticated =>
      _tokenManager.accessToken != null &&
      _tokenManager.accessToken!.isNotEmpty;

  Future<void> startSession({
    required String accessToken,
    required String refreshToken,
  }) =>
      _tokenManager.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );

  Future<void> logout() => _tokenManager.clearTokens();
}
