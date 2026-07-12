import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:network/network.dart' show AuthInterceptor;
import 'package:network/src/interceptors/auth_interceptor.dart' show AuthInterceptor;

import 'package:network/src/network_config.dart';
import 'package:network/src/token/token_manager.dart';
import 'package:network/src/token/token_refresh_model.dart';
import 'package:network/src/token/token_storage.dart';

/// Concrete [TokenManager] using a raw, unintercepted [Dio] for refresh calls.
///
/// The raw [Dio] must NOT have [AuthInterceptor] attached — that would cause
/// an infinite 401 refresh loop.
class TokenManagerImpl implements TokenManager {
  TokenManagerImpl(this._rawDio, this._tokenStorage, this._config);

  final Dio _rawDio;
  final TokenStorage _tokenStorage;
  final NetworkConfig _config;

  String? _accessToken;
  String? _refreshToken;

  @override
  String? get accessToken => _accessToken;

  @override
  String? get refreshToken => _refreshToken;

  @override
  Future<void> init() async {
    final results = await Future.wait([
      _tokenStorage.getToken(),
      _tokenStorage.getRefreshToken(),
    ]);
    _accessToken = results[0];
    _refreshToken = results[1];
    if (kDebugMode) debugPrint('[TokenManager] initialized');
  }

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    await _tokenStorage.saveToken(accessToken);
    await _tokenStorage.saveRefreshToken(refreshToken);
  }

  @override
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    await _tokenStorage.clearToken();
  }

  @override
  Future<String> refreshAccessToken() async {
    final stored = refreshToken;
    if (stored == null || stored.isEmpty) {
      throw const TokenRefreshException(
        'No refresh token stored — user must sign in again.',
      );
    }
    try {
      final response = await _rawDio.post<Map<String, dynamic>>(
        _config.refreshTokenPath,
        data: {'refreshToken': stored},
      );
      final data = response.data;
      if (data == null) {
        throw const TokenRefreshException('Refresh response body was null.');
      }
      final model = TokenRefreshModel.fromJson(data);
      await saveTokens(
        accessToken: model.accessToken,
        refreshToken: model.refreshToken,
      );
      return model.accessToken;
    } on DioException catch (e) {
      throw TokenRefreshException(
        'Refresh endpoint failed: ${e.response?.statusCode} ${e.message}',
      );
    }
  }
}
