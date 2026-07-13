/// DTO for the token-refresh endpoint response.
class TokenRefreshModel {
  const TokenRefreshModel({
    required this.accessToken,
    required this.refreshToken,
  });

  factory TokenRefreshModel.fromJson(Map<String, dynamic> json) =>
      TokenRefreshModel(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
      );

  final String accessToken;
  final String refreshToken;

  @override
  String toString() =>
      'TokenRefreshModel(accessToken: [redacted], refreshToken: [redacted])';
}
