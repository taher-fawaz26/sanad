import 'package:auth/src/domain/entities/user_entity.dart';
import 'package:auth/src/domain/usecases/get_current_user_usecase.dart';
import 'package:auth/src/session/session_manager.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

/// Composes and persists a full session from an ACTIVE `login/verify` (or
/// `social/login`) result.
///
/// `LoginResponseDto` carries only tokens + status — no user/profile
/// payload — so completing an ACTIVE login requires a follow-up `GET /me`
/// call to learn who actually signed in. Tokens are primed into the token
/// layer first (via [SessionManager.primeTokens]) so that call is
/// authenticated, then the composed session is persisted in one step via
/// [SessionManager.saveFromIdentity]. Shared by [AuthBloc] (Google sign-in)
/// and `EmailOtpPage` (OTP sign-in) so the two call sites can't drift.
TaskEither<Failure, UserEntity> completeActiveLogin({
  required String accessToken,
  required String refreshToken,
  required GetCurrentUserUseCase getCurrentUser,
  required SessionManager sessionManager,
}) {
  return TaskEither<Failure, void>.tryCatch(
        () => sessionManager.primeTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        ),
        (error, _) => UnknownFailure(message: error.toString()),
      )
      .flatMap((_) => getCurrentUser(const NoParams()))
      .flatMap(
        (identity) => TaskEither<Failure, UserEntity>.tryCatch(
          () async {
            await sessionManager.saveFromIdentity(
              accessToken: accessToken,
              refreshToken: refreshToken,
              identity: identity,
            );
            return UserEntity(
              id: identity.id,
              email: identity.email,
              isVerified: true,
              isActive: true,
              type: identity.userType,
            );
          },
          (error, _) => UnknownFailure(message: error.toString()),
        ),
      );
}
