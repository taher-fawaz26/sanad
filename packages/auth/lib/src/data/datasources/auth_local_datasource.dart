import 'package:auth/src/data/models/user_model.dart';
import 'package:auth/src/domain/entities/user_entity.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';
import 'package:storage/storage.dart';

abstract class AuthLocalDataSource {
  /// Returns [UserEntity] if a valid access token exists and user is in cache.
  TaskEither<Failure, UserEntity?> checkSignInStatus();
  TaskEither<Failure, void> saveUser(UserEntity user);
  TaskEither<Failure, void> clearUser();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  const AuthLocalDataSourceImpl(this._tokenManager, this._localStorage);

  final TokenManager _tokenManager;
  final HiveLocalStorage _localStorage;

  @override
  TaskEither<Failure, UserEntity?> checkSignInStatus() {
    return TaskEither.tryCatch(
      () async {
        final accessToken = _tokenManager.accessToken;
        if (accessToken == null || accessToken.isEmpty) return null;

        final raw = await _localStorage.load(
          key: StorageKeys.userEntity,
          boxName: HiveBoxes.user,
        );

        if (raw == null) return null;

        // Stored as either a UserEntity (Hive adapter) or a Map
        // (JSON fallback).
        if (raw is UserEntity) return raw;
        if (raw is Map) {
          return UserModel.fromJson(Map<String, dynamic>.from(raw));
        }
        return null;
      },
      (error, _) =>
          const CacheFailure(message: ErrorMessages.cacheError),
    );
  }

  @override
  TaskEither<Failure, void> saveUser(UserEntity user) {
    return TaskEither.tryCatch(
      () => _localStorage.save(
        key: StorageKeys.userEntity,
        value: user,
        boxName: HiveBoxes.user,
      ),
      (error, _) =>
          const CacheFailure(message: ErrorMessages.cacheError),
    );
  }

  @override
  TaskEither<Failure, void> clearUser() {
    return TaskEither.tryCatch(
      () => _localStorage.delete(
        key: StorageKeys.userEntity,
        boxName: HiveBoxes.user,
      ),
      (error, _) =>
          const CacheFailure(message: ErrorMessages.cacheError),
    );
  }
}
