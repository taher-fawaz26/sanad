import 'package:auth/src/domain/entities/user_entity.dart';
import 'package:auth/src/session/session_manager.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

/// Reads whether a rehydrated session is active on the device.
///
/// After the refactor this is a thin adapter over [SessionManager.current] —
/// the session layer has already been restored from Hive during app
/// bootstrap ([AuthModule.initialize]), so this use case never touches disk.
class AuthCheckSignInStatusUseCase implements UseCase<UserEntity?, NoParams> {
  const AuthCheckSignInStatusUseCase(this._sessionManager);

  final SessionManager _sessionManager;

  @override
  TaskEither<Failure, UserEntity?> call(NoParams params) {
    return TaskEither.tryCatch(
      () async => _sessionManager.current()?.user,
      (error, _) => UnknownFailure(message: error.toString()),
    );
  }
}
