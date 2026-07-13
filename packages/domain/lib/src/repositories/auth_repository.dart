import 'package:core/core.dart';
import 'package:domain/src/entities/user_entity.dart';
import 'package:fpdart/fpdart.dart';

/// Repository contract for authentication operations.
/// Concrete implementation lives in the data layer.
abstract class AuthRepository {
  /// Authenticates with [identifier] and [password], returning tokens and the
  /// resolved [UserEntity] on success.
  TaskEither<Failure,
      ({String accessToken, String refreshToken, UserEntity user})> login({
    required String identifier,
    required String password,
  });

  /// Invalidates the current session on both client and server.
  TaskEither<Failure, void> logout();

  /// Creates a new account with the given [identifier], [password], and [role].
  TaskEither<Failure, void> register({
    required String identifier,
    required String password,
    required String role,
  });

  /// Returns the cached [UserEntity] when a valid session exists, or null.
  TaskEither<Failure, UserEntity?> checkSignInStatus();

  /// Verifies a one-time password and returns tokens with the resolved user.
  TaskEither<Failure,
      ({String accessToken, String refreshToken, UserEntity user})>
      validateOtp({
    required String identifier,
    required int otp,
  });

  /// Sends a forgot-password OTP to the given [identifier].
  TaskEither<Failure, void> requestForgotPassword({required String identifier});

  /// Confirms the forgot-password [otp] for the given [identifier].
  TaskEither<Failure, void> verifyForgotPasswordOtp({
    required String identifier,
    required int otp,
  });

  /// Updates the account password to [newPassword] after OTP verification.
  TaskEither<Failure, void> resetPassword({
    required String identifier,
    required String newPassword,
  });

  /// Resends an OTP for the given [identifier] and [purpose].
  TaskEither<Failure, void> resendOtp({
    required String identifier,
    required String purpose,
  });

  /// Permanently removes the account identified by [userSub].
  TaskEither<Failure, void> deleteAccount({required String userSub});
}
