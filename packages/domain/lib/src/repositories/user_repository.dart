import 'package:core/core.dart';
import 'package:domain/src/entities/user_entity.dart';
import 'package:fpdart/fpdart.dart';

/// Repository contract for user profile operations.
/// Implemented in the data layer (sand_api / feature data source).
abstract class UserRepository {
  /// Returns the authenticated user's profile from local cache or remote.
  TaskEither<Failure, UserEntity> getProfile();

  /// Persists the user entity to local cache.
  TaskEither<Failure, void> saveProfile(UserEntity user);

  /// Clears locally cached user data.
  TaskEither<Failure, void> clearProfile();
}
