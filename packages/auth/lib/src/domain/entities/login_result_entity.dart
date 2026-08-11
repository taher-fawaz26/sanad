import 'package:auth/src/domain/enums/auth_account_status.dart';
import 'package:equatable/equatable.dart';

/// Parsed `LoginResponseDto` — the single-shape response returned by both
/// `POST /auth/login/verify` and `POST /auth/social/login`.
///
/// The wire shape is intentionally overloaded by [status]:
/// - `active` — [accessToken] / [refreshToken] are a real, usable session.
/// - `incomplete` — [accessToken] IS the onboarding token (short-lived,
///   `auth/profile`/`auth/extract` only); [refreshToken] is always null.
///   Never persist it as a session token.
/// - `suspended` — both are null.
class LoginResult extends Equatable {
  const LoginResult({
    required this.status,
    this.accessToken,
    this.refreshToken,
  });

  final AuthAccountStatus status;
  final String? accessToken;
  final String? refreshToken;

  @override
  List<Object?> get props => [status, accessToken, refreshToken];
}
